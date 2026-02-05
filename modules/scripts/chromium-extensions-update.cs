#!/usr/bin/dotnet run

#:package System.CommandLine@2.0.2
#:package Spectre.Console@0.54.1-alpha.0.36
#:package Tommy@3.1.2
#:property Nullable=enable

using System.CommandLine;
using System.Diagnostics;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Spectre.Console;
using Tommy;

string? _cachedChromiumVersion = null;

Option<string> inputOpt = new("--input", "-i") { Description = "Specify the input TOML file", Required = true };
Option<string> outputOpt = new("--output", "-o") { Description = "Specify the output Nix file", Required = true };

RootCommand root = new("Generates a Nix file for Chromium extensions from a TOML configuration file")
{
    inputOpt,
    outputOpt
};

root.SetAction(async (parseResult, _) =>
{
    try
    {
        var inputFile = parseResult.GetValue(inputOpt)!;
        var outputFile = parseResult.GetValue(outputOpt)!;

        if (!File.Exists(inputFile))
        {
            Log.Error($"Input file not found: {inputFile}");
            return 1;
        }

        AnsiConsole.Write(new FigletText("Extensions").Color(Color.Blue));
        Log.Header($"{Icons.File} {inputFile}");
        Log.Info($"Output: {outputFile}");

        var (extensions, config, hasConditions) = ParseToml(inputFile);
        if (extensions.Count is 0)
        {
            Log.Warning($"No extensions found in {inputFile}");
            return 0;
        }

        Log.Info($"Found {extensions.Count} extension(s) to process");

        _cachedChromiumVersion = await GetChromiumMajorVersionAsync();
        Log.Info($"{Icons.Chromium} Chromium version: {_cachedChromiumVersion}");

        var results = await ProcessExtensionsWithProgress(extensions, config);
        var errors = results.Where(r => r.Error != null).ToList();

        if (errors.Count > 0)
        {
            AnsiConsole.WriteLine();
            Log.Error($"Failed to process {errors.Count} extension(s):");
            foreach (var e in errors)
                Log.ExtensionStatus(0, 0, e.Extension.Name ?? e.Extension.Id, "", false, e.Error);
            return 1;
        }

        await GenerateNixFile(outputFile, results, hasConditions);
        await FormatNixFile(outputFile);
        await ValidateNixFile(outputFile);

        AnsiConsole.WriteLine();
        Log.Success($"Generated {outputFile}");
        return 0;
    }
    catch (Exception ex)
    {
        Log.Error($"Unhandled exception: {ex.Message}");
        return 1;
    }
});

return await root.Parse(args).InvokeAsync();

GithubReleaseConfig ParseGithubConfig(TomlTable table)
{
    if (!table.HasKey("config")) return new GithubReleaseConfig();
    var configTable = table["config"].AsTable;
    if (!configTable.HasKey("sources")) return new GithubReleaseConfig();
    var sourcesTable = configTable["sources"].AsTable;
    if (!sourcesTable.HasKey("github-releases")) return new GithubReleaseConfig();

    var ghTable = sourcesTable["github-releases"].AsTable;
    return new GithubReleaseConfig(
        Owner: ghTable["owner"]?.AsString?.Value,
        Repo: ghTable["repo"]?.AsString?.Value,
        Pattern: ghTable["pattern"]?.AsString?.Value);
}

Extension? TryParseExtension(TomlTable extTable, ref bool hasConditions)
{
    var id = extTable["id"]?.AsString?.Value;
    if (string.IsNullOrEmpty(id))
    {
        Log.Warning("Extension missing 'id' field, skipping");
        return null;
    }

    var condition = extTable["condition"]?.AsString?.Value;
    if (!string.IsNullOrEmpty(condition)) hasConditions = true;

    return new Extension(
        Id: id,
        Name: extTable["name"]?.AsString?.Value,
        Source: extTable["source"]?.AsString?.Value ?? "chrome-store",
        Url: extTable["url"]?.AsString?.Value,
        Condition: condition,
        Owner: extTable["owner"]?.AsString?.Value,
        Repo: extTable["repo"]?.AsString?.Value,
        Pattern: extTable["pattern"]?.AsString?.Value,
        Version: extTable["version"]?.AsString?.Value);
}

(List<Extension> Extensions, GithubReleaseConfig Config, bool HasConditions) ParseToml(
    string tomlFile)
{
    using var reader = File.OpenText(tomlFile);
    var table = TOML.Parse(reader);

    var extensions = new List<Extension>();
    var hasConditions = false;
    var config = ParseGithubConfig(table);

    if (!table.HasKey("extensions"))
        return (extensions, config, hasConditions);

    foreach (var node in table["extensions"].AsArray.Children)
    {
        if (TryParseExtension(node.AsTable, ref hasConditions) is { } ext)
            extensions.Add(ext);
    }

    return (extensions, config, hasConditions);
}

async Task<List<ExtensionResult>> ProcessExtensionsWithProgress(List<Extension> extensions,
    GithubReleaseConfig config)
{
    List<ExtensionResult> results = [];
    var completed = 0;

    AnsiConsole.WriteLine();
    Log.Header($"{Icons.Extensions} Processing Extensions");

    await AnsiConsole.Progress()
        .AutoClear(true)
        .Columns(new TaskDescriptionColumn(),
            new ProgressBarColumn(),
            new PercentageColumn(),
            new RemainingTimeColumn())
        .StartAsync(async ctx =>
        {
            var semaphore = new SemaphoreSlim(5, 5);
            var tasks = extensions.Select(async ext =>
            {
                var task = ctx.AddTask(ext.Name ?? ext.Id, maxValue: 100);
                await semaphore.WaitAsync();
                try
                {
                    var result = await ProcessExtensionQuiet(ext, config, task);
                    lock (results)
                    {
                        results.Add(result);
                        completed++;
                        Log.ExtensionStatus(completed, extensions.Count, ext.Name ?? ext.Id,
                            result.Error is null ? result.Version : null,
                            result.Error is null, result.Error);
                    }
                }
                finally
                {
                    task.Value = 100;
                    semaphore.Release();
                }
            });

            await Task.WhenAll(tasks);
        });

    return results;
}

async Task<ExtensionResult> ProcessExtensionQuiet(Extension ext, GithubReleaseConfig config, ProgressTask? task = null)
{
    try
    {
        task?.Increment(10);

        string? finalUrl;
        switch (ext.Source)
        {
            case "chrome-store":
                finalUrl = await FetchChromeStoreUrlAsync(ext.Id, task);
                break;
            case "bpc":
                finalUrl = await FetchBpcUrlAsync();
                break;
            case "url":
                if (string.IsNullOrEmpty(ext.Url))
                    return new ExtensionResult(ext, $"Extension '{ext.Id}' has source 'url' but no 'url' field specified", null, null);
                finalUrl = ext.Url;
                break;
            case "github-releases":
                finalUrl = await FetchGithubReleaseUrlAsync(ext, config);
                break;
            default:
                return new ExtensionResult(ext, $"Unknown source '{ext.Source}' for extension '{ext.Id}'", null, null);
        }

        if (string.IsNullOrEmpty(finalUrl))
            return new ExtensionResult(ext, "Failed to get download URL", null, null);

        task?.Increment(20);

        var tempFile = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.crx");
        try
        {
            using var httpClient = new HttpClient();
            await using var stream = await httpClient.GetStreamAsync(finalUrl);
            await using var fileStream = File.Create(tempFile);
            await stream.CopyToAsync(fileStream);
        }
        catch (Exception ex) { return new ExtensionResult(ext, $"Failed to download: {ex.Message}", null, null); }

        task?.Increment(40);

        try
        {
            var hash = await CalculateNixHashAsync(tempFile);
            task?.Increment(20);
            var version = await ExtractVersionFromCrxAsync(tempFile);
            task?.Increment(10);
            var nixEntry = GenerateNixEntry(ext, finalUrl, hash, version);
            return new ExtensionResult(ext, null, nixEntry, version);
        }
        finally { if (File.Exists(tempFile)) File.Delete(tempFile); }
    }
    catch (Exception ex) { return new ExtensionResult(ext, ex.Message, null, null); }
}

async Task<string?> FetchChromeStoreUrlAsync(string extensionId, ProgressTask? task = null)
{
    var prodversion = _cachedChromiumVersion ?? await GetChromiumMajorVersionAsync();
    task?.Increment(10);

    var xParam = Uri.EscapeDataString($"id={extensionId}&installsource=ondemand&uc");

    UriBuilder uriBuilder = new("https", "clients2.google.com")
    {
        Path = "/service/update2/crx",
        Query = new StringBuilder()
            .Append("response=redirect")
            .Append("&acceptformat=crx2,crx3")
            .Append($"&prodversion={Uri.EscapeDataString(prodversion)}")
            .Append($"&x={xParam}")
            .ToString()
    };

    using var httpClient = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false });
    var response = await httpClient.GetAsync(uriBuilder.Uri);

    return (int)response.StatusCode is 302 or 301 ? response.Headers.Location?.ToString() : null;
}

async Task<string> GetChromiumMajorVersionAsync()
{
    if (_cachedChromiumVersion != null)
        return _cachedChromiumVersion;

    try
    {
        var output = await RunProcessAsync("nix", "eval --impure --expr 'with import <nixpkgs> {}; lib.getVersion chromium'");
        var version = output.Trim().Trim('"').Split('.')[0];
        if (int.TryParse(version, out _))
        {
            _cachedChromiumVersion = version;
            return version;
        }
    }
    catch { /* ignore */ }

    Log.Warning("Could not determine Chromium version, using default: 143");
    _cachedChromiumVersion = "143";
    return _cachedChromiumVersion;
}

async Task<string?> FetchBpcUrlAsync()
{
    const string bpcRepo = "https://gitflic.ru/project/magnolia1234/bpc_uploads.git";

    var output = await RunProcessAsync("git", $"ls-remote {bpcRepo} HEAD");
    var commit = output.Split('\t')[0];

    if (string.IsNullOrEmpty(commit))
        throw new InvalidOperationException("Failed to get latest commit for bypass-paywalls-chrome");

    UriBuilder uriBuilder = new("https", "gitflic.ru")
    {
        Path = "/project/magnolia1234/bpc_uploads/blob/raw",
        Query = new StringBuilder()
            .Append("file=bypass-paywalls-chrome-clean-latest.crx")
            .Append("&inline=false")
            .Append($"&commit={Uri.EscapeDataString(commit)}")
            .ToString()
    };

    return uriBuilder.Uri.ToString();
}

async Task<string?> FetchGithubReleaseUrlAsync(Extension ext, GithubReleaseConfig config)
{
    var owner = ext.Owner ?? config.Owner ?? throw new InvalidOperationException("GitHub release source requires 'owner' field");
    var repo = ext.Repo ?? config.Repo ?? throw new InvalidOperationException("GitHub release source requires 'repo' field");
    var pattern = ext.Pattern ?? config.Pattern;
    var version = ext.Version ?? "latest";

    string finalVersion;
    if (version != "latest")
    {
        finalVersion = version.TrimStart('v');
    }
    else
    {
        using HttpClient httpClient = new();
        httpClient.DefaultRequestHeaders.Add("User-Agent", "ChromiumExtensionsUpdater");
        httpClient.DefaultRequestHeaders.Add("Accept", "application/vnd.github.v3+json");

        var githubToken = GetGitHubToken();
        if (!string.IsNullOrEmpty(githubToken))
            httpClient.DefaultRequestHeaders.Add("Authorization", $"token {githubToken}");

        UriBuilder uriBuilder = new("https", "api.github.com")
        {
            Path = $"/repos/{owner}/{repo}/releases/latest"
        };

        var response = await httpClient.GetStringAsync(uriBuilder.Uri);
        var release = JsonSerializer.Deserialize(response, GitHubReleaseContext.Default.GitHubRelease);

        var tagName = release.TagName ?? release.Name;
        if (string.IsNullOrEmpty(tagName))
            throw new InvalidOperationException("Failed to get latest release version from GitHub API");

        finalVersion = tagName.TrimStart('v');
    }

    string finalUrl;
    if (!string.IsNullOrEmpty(pattern))
    {
        var path = pattern
            .Replace("{version}", finalVersion)
            .Replace("{name}", ext.Id)
            .Replace("{id}", ext.Id);
        finalUrl = BuildGithubUrl(owner, repo, path);
    }
    else
    {
        finalUrl = BuildGithubReleaseDownloadUrl(owner, repo, finalVersion, ext.Id);
    }

    return finalUrl;
}

string BuildGithubUrl(string owner, string repo, string path)
{
    UriBuilder uriBuilder = new("https", "github.com")
    {
        Path = $"/{owner}/{repo}/{path}"
    };
    return uriBuilder.Uri.ToString();
}

string BuildGithubReleaseDownloadUrl(string owner, string repo, string version, string assetName)
{
    UriBuilder uriBuilder = new("https", "github.com")
    {
        Path = $"/{owner}/{repo}/releases/download/v{version}/{assetName}.crx"
    };
    return uriBuilder.Uri.ToString();
}

async Task<string> CalculateNixHashAsync(string filePath)
{
    await using var stream = File.OpenRead(filePath);
    using var sha256 = SHA256.Create();
    var hash = await sha256.ComputeHashAsync(stream);
    var hexHash = Convert.ToHexString(hash).ToLowerInvariant();

    var output = await RunProcessAsync("nix", $"hash to-sri --type sha256 {hexHash}");
    return output.Trim();
}

async Task<string> ExtractVersionFromCrxAsync(string crxPath)
{
    await using var fileStream = File.OpenRead(crxPath);
    var headerBytes = new byte[4];
    await fileStream.ReadExactlyAsync(headerBytes);

    string zipPath;
    if (Encoding.ASCII.GetString(headerBytes) is "Cr24")
    {
        fileStream.Position = 0;
        var allBytes = await File.ReadAllBytesAsync(crxPath);
        var zipOffset = FindPattern(allBytes.AsSpan(), [0x50, 0x4B, 0x03, 0x04]);

        if (zipOffset > 0)
        {
            zipPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.zip");
            await File.WriteAllBytesAsync(zipPath, allBytes[zipOffset..]);
        }
        else
        {
            zipPath = crxPath;
        }
    }
    else
    {
        zipPath = crxPath;
    }

    try
    {
        await using var zip = await ZipFile.OpenReadAsync(zipPath);
        var manifestEntry = zip.GetEntry("manifest.json")
            ?? throw new InvalidOperationException("manifest.json not found in extension archive");

        await using var manifestStream = await manifestEntry.OpenAsync();
        using var reader = new StreamReader(manifestStream);
        var manifestJson = await reader.ReadToEndAsync();
        using var manifest = JsonDocument.Parse(manifestJson);

        var version = manifest.RootElement.TryGetProperty("version", out var v) ? v.GetString() : null;
        if (string.IsNullOrEmpty(version) && manifest.RootElement.TryGetProperty("version_name", out var vn))
            version = vn.GetString();

        return version ?? throw new InvalidOperationException("Could not extract version from manifest");
    }
    finally { if (zipPath != crxPath && File.Exists(zipPath)) File.Delete(zipPath); }
}

int FindPattern(ReadOnlySpan<byte> data, ReadOnlySpan<byte> pattern)
{
    for (var i = 0; i <= data.Length - pattern.Length; i++)
        if (data.Slice(i, pattern.Length).SequenceEqual(pattern))
            return i;
    return -1;
}

string GenerateNixEntry(Extension ext, string url, string hash, string version)
{
    var id = EscapeNix(ext.Id);
    var safeUrl = EscapeNix(url);
    var safeHash = EscapeNix(hash);
    var safeVersion = EscapeNix(version);

    var entry = $$"""
      {
        id = "{{id}}";
        crxPath = pkgs.fetchurl {
          url = "{{safeUrl}}";
          name = "{{id}}.crx";
          hash = "{{safeHash}}";
        };
        version = "{{safeVersion}}";
      }
      """;

    return entry;
}

string EscapeNix(string s) =>
    s.Replace("\\", @"\\").Replace("\"", "\\\"").Replace("$", "\\$");

async Task GenerateNixFile(string outputFile, List<ExtensionResult> results, bool hasConditions)
{
    var configParam = hasConditions ? "  config," + Environment.NewLine : "";

    var unconditionalEntries = results
        .Where(r => string.IsNullOrEmpty(r.Extension.Condition) && r.NixEntry != null)
        .OrderBy(r => r.Extension.Id).ToList();
    var conditionalEntries = results
    .Where(r => !string.IsNullOrEmpty(r.Extension.Condition) && r.NixEntry != null)
        .OrderBy(r => r.Extension.Id).ToList();

    var sb = new StringBuilder();
    sb.AppendLine($"# This file is auto-generated by an update script");
    sb.AppendLine($"# DO NOT edit manually");
    sb.AppendLine($"{{");
    sb.AppendLine($"  pkgs,");
    sb.Append(configParam);
    sb.AppendLine($"  lib,");
    sb.AppendLine($"  ...");
    sb.AppendLine($"}}:");
    sb.AppendLine($"lib.flatten [");

    foreach (var entry in unconditionalEntries)
        sb.AppendLine(entry.NixEntry);

    foreach (var entry in conditionalEntries)
    {
        var condition = EscapeNix(entry.Extension.Condition!);
        sb.AppendLine($"  (lib.optionals ({condition}) [");
        sb.AppendLine(entry.NixEntry);
        sb.AppendLine($"  ])");
    }

    sb.AppendLine($"]");

    var dir = Path.GetDirectoryName(outputFile);
    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

    await File.WriteAllTextAsync(outputFile, sb.ToString());
}

async Task FormatNixFile(string outputFile)
{
    try { await RunProcessAsync("nixfmt", outputFile); }
    catch { /* ignored */ }
}

async Task ValidateNixFile(string outputFile)
{
    try { await RunProcessAsync("nix-instantiate", $"--parse {outputFile}"); }
    catch { throw new InvalidOperationException("Generated nix file is invalid"); }
}

async Task<string> RunProcessAsync(string command, string arguments, string? workingDir = null)
{
    ProcessStartInfo psi = new()
    {
        FileName = command,
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        WorkingDirectory = workingDir
    };

    // We use ArgumentList so we can properly handle quotes
    foreach (var arg in ParseArguments(arguments))
        psi.ArgumentList.Add(arg);

    using var process = Process.Start(psi) ?? throw new InvalidOperationException($"Failed to start process: {command}");
    var output = await process.StandardOutput.ReadToEndAsync();
    var error = await process.StandardError.ReadToEndAsync();
    await process.WaitForExitAsync();

    return process.ExitCode != 0
        ? throw new InvalidOperationException($"Process {command} exited with code {process.ExitCode}: {error}")
        : output;
}

static List<string> ParseArguments(string arguments)
{
    var args = new List<string>();
    var current = new StringBuilder();
    bool inQuotes = false;

    for (int i = 0; i < arguments.Length; i++)
    {
        char c = arguments[i];

        if (c == '\'')
        {
            inQuotes = !inQuotes;
        }
        else if (c == ' ' && !inQuotes)
        {
            if (current.Length > 0)
            {
                args.Add(current.ToString());
                current.Clear();
            }
        }
        else
        {
            current.Append(c);
        }
    }

    if (current.Length > 0)
        args.Add(current.ToString());

    return args;
}

string? GetGitHubToken()
{
    var envToken = Environment.GetEnvironmentVariable("GITHUB_TOKEN");
    if (!string.IsNullOrEmpty(envToken))
        return envToken;

    try
    {
        var ghToken = RunProcessAsync("gh", "auth token").Result.Trim();
        if (!string.IsNullOrEmpty(ghToken) && ghToken.StartsWith("gho_"))
            return ghToken;
    }
    catch { /* ignore */ }

    return null;
}

readonly record struct Extension(
    string Id,
    string? Name,
    string Source,
    string? Url,
    string? Condition,
    string? Owner,
    string? Repo,
    string? Pattern,
    string? Version
);

readonly record struct GithubReleaseConfig(string? Owner, string? Repo, string? Pattern);

readonly record struct ExtensionResult(Extension Extension, string? Error, string? NixEntry, string? Version);

readonly record struct GitHubRelease(
    [property: JsonPropertyName("tag_name")] string? TagName,
    [property: JsonPropertyName("name")] string? Name
);

[JsonSerializable(typeof(GitHubRelease))]
partial class GitHubReleaseContext : JsonSerializerContext;

static class Icons
{
    public const string Info = "\uf449";        // nf-oct-info
    public const string Success = "\uf42e";     // nf-oct-check
    public const string Warning = "\uf421";     // nf-oct-alert
    public const string Error = "\uf467";       // nf-oct-x_circle
    public const string File = "\uf471";        // nf-oct-file
    public const string Chromium = "\uf268";    // nf-fa-chrome
    public const string Extensions = "\uf40e";  // nf-oct-apps
}

static class Log
{
    public static void Header(string message) =>
        AnsiConsole.Write(new Rule($"[blue]{Escape(message)}[/]").RuleStyle("blue")
            .LeftJustified());

    public static void Info(string message) =>
        AnsiConsole.MarkupLine($"  {Icons.Info} [dim]{Escape(message)}[/]");

    public static void Success(string message) =>
        AnsiConsole.MarkupLine($"  {Icons.Success} [green]{Escape(message)}[/]");

    public static void Warning(string message) =>
        AnsiConsole.MarkupLine($"  {Icons.Warning} [yellow]{Escape(message)}[/]");

    public static void Error(string message) =>
        AnsiConsole.MarkupLine($"  {Icons.Error} [red]{Escape(message)}[/]");

    public static void ExtensionStatus(int current,
        int total,
        string name,
        string? version,
        bool success,
        string? error = null)
    {
        var icon = success ? $"[green]{Icons.Success}[/]" : $"[red]{Icons.Error}[/]";
        var count = $"[dim][[{current}/{total}]][/]";
        var nameColored = $"[white]{Escape(name)}[/]";
        var versionDisplay = success && !string.IsNullOrEmpty(version) ? $"[dim]v{Escape(version)}[/]" : "";
        var errorMsg = error != null ? $"[red] {Escape(error)}[/]" : "";
        AnsiConsole.MarkupLine($"  {icon} {count} {nameColored} {versionDisplay}{errorMsg}");
    }

    private static string Escape(string s) =>
        s.Replace("[", "[[").Replace("]", "]]]");
}
