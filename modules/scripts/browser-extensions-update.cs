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

HttpClient client = new();
HttpClient chromeStoreClient = new(new HttpClientHandler { AllowAutoRedirect = false });

Option<string> inputOpt = new("--input", "-i")
{
    Description = "Specify the input TOML file",
    Required = true
};
Option<string> outputOpt = new("--output", "-o")
{
    Description = "Specify the output Nix file (default: input file with .nix extension)",
    Required = false
};
Option<string> browserOpt = new("--browser", "-b")
{
    Description = "Browser type (chromium or firefox)",
    Required = true
};

RootCommand root = new("Generates a Nix file for browser extensions from a TOML configuration file")
{
    inputOpt,
    outputOpt,
    browserOpt
};

root.SetAction(async (parseResult, _) =>
{
    try
    {
        var inputFile = parseResult.GetValue(inputOpt)!;
        var outputFile = parseResult.GetValue(outputOpt) ?? Path.ChangeExtension(inputFile, ".nix");
        var browserInput = parseResult.GetValue(browserOpt)!.ToLowerInvariant();

        if (!File.Exists(inputFile))
        {
            Log.Error($"Input file not found: {inputFile}");
            return 1;
        }

        if (!Enum.TryParse<BrowserType>(browserInput, true, out var browser))
        {
            Log.Error($"Invalid browser type: {browserInput}. Must be 'chromium' or 'firefox'.");
            return 1;
        }

        AnsiConsole.Write(new FigletText("Extensions").Color(Color.Blue));
        Log.Header($"{Icons.File} {inputFile}");
        Log.Info($"Output: {outputFile}");
        Log.Info($"Browser: {browser}");

        var (extensions, config, hasConditions) = ParseToml(inputFile);
        if (extensions.Count is 0)
        {
            Log.Warning($"No extensions found in {inputFile}");
            return 0;
        }

        Log.Info($"Found {extensions.Count} extension(s) to process");

        string? browserVersion = null;
        if (browser == BrowserType.Chromium)
        {
            browserVersion = await GetChromiumMajorVersionAsync(null);
            Log.Info($"{Icons.Chromium} Chromium version: {browserVersion}");
        }
        else
        {
            Log.Info($"{Icons.Firefox} Firefox extensions");
        }

        var results = await ProcessExtensionsWithProgress(extensions, config, browser, browserVersion);
        var errors = results.Where(r => r.Error != null).ToList();

        if (errors.Count > 0)
        {
            AnsiConsole.WriteLine();
            Log.Error($"Failed to process {errors.Count} extension(s):");
            foreach (var e in errors)
                Log.ExtensionStatus(0, 0, e.Extension.Name ?? e.Extension.Id, "", false, e.Error);
            return 1;
        }

        await GenerateNixFile(outputFile, results, hasConditions, browser);
        await ProcessUtils.RunAsync("nix", $"run nixpkgs#nixfmt -- {outputFile}");
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

    var sourceStr = extTable["source"]?.AsString?.Value ?? "chrome-store";
    if (Enum.TryParse<ExtensionSource>(sourceStr.Replace("-", ""), true, out var source))
        return new Extension(
            Id: id,
            Name: extTable["name"]?.AsString?.Value,
            Source: source,
            Url: extTable["url"]?.AsString?.Value,
            Condition: condition,
            Owner: extTable["owner"]?.AsString?.Value,
            Repo: extTable["repo"]?.AsString?.Value,
            Pattern: extTable["pattern"]?.AsString?.Value,
            Version: extTable["version"]?.AsString?.Value);

    Log.Warning($"Unknown source '{sourceStr}' for extension '{id}', defaulting to ChromeStore");
    source = ExtensionSource.ChromeStore;

    return new Extension(
        Id: id,
        Name: extTable["name"]?.AsString?.Value,
        Source: source,
        Url: extTable["url"]?.AsString?.Value,
        Condition: condition,
        Owner: extTable["owner"]?.AsString?.Value,
        Repo: extTable["repo"]?.AsString?.Value,
        Pattern: extTable["pattern"]?.AsString?.Value,
        Version: extTable["version"]?.AsString?.Value);
}

(List<Extension> Extensions, GithubReleaseConfig Config, bool HasConditions) ParseToml(string tomlFile)
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
    GithubReleaseConfig config,
    BrowserType browser,
    string? browserVersion)
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
                    var result = await ProcessExtensionQuiet(ext, config, browser, browserVersion, task);
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

async Task<ExtensionResult> ProcessExtensionQuiet(Extension ext,
    GithubReleaseConfig config,
    BrowserType browser,
    string? browserVersion,
    ProgressTask? task = null)
{
    try
    {
        task?.Increment(10);

        var sourceHandler = new ExtensionSourceHandler(client, chromeStoreClient);
        var (finalUrl, error) = await sourceHandler.FetchUrlAsync(ext, config, browser, browserVersion, task);

        if (error != null)
            return new ExtensionResult(ext, error, null, null, null);

        if (string.IsNullOrEmpty(finalUrl))
            return new ExtensionResult(ext, "Failed to get download URL", null, null, null);

        task?.Increment(20);

        var extension = browser.GetFileExtension();
        var tempFile = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.{extension}");
        try
        {
            await using var stream = await client.GetStreamAsync(finalUrl);
            await using var fileStream = File.Create(tempFile);
            await stream.CopyToAsync(fileStream);
        }
        catch (Exception ex) { return new ExtensionResult(ext, $"Failed to download: {ex.Message}", null, null, null); }

        task?.Increment(40);

        try
        {
            var hash = await CalculateNixHashAsync(tempFile);
            task?.Increment(20);
            var (version, permissions) = await ExtractVersionAndPermissionsAsync(tempFile);
            task?.Increment(10);
            var nixEntry = NixEntryGenerator.Generate(ext, finalUrl, hash, version, permissions, browser);
            return new ExtensionResult(ext, null, nixEntry, version, permissions);
        }
        finally { if (File.Exists(tempFile)) File.Delete(tempFile); }
    }
    catch (Exception ex) { return new ExtensionResult(ext, ex.Message, null, null, null); }
}

async Task<string> GetChromiumMajorVersionAsync(string? cachedVersion)
{
    if (cachedVersion != null)
        return cachedVersion;

    try
    {
        var output = await ProcessUtils.RunAsync("nix",
            "eval --impure --expr 'with import <nixpkgs> {}; lib.getVersion chromium'");
        var version = output.Trim().Trim('"').Split('.')[0];
        if (int.TryParse(version, out _))
            return version;
    }
    catch { /* ignore */ }

    Log.Warning("Could not determine Chromium version, using default: 143");
    return "143";
}

async Task<string> CalculateNixHashAsync(string filePath)
{
    await using var stream = File.OpenRead(filePath);
    using var sha256 = SHA256.Create();
    var hash = await sha256.ComputeHashAsync(stream);
    var hexHash = Convert.ToHexString(hash).ToLowerInvariant();

    var output = await ProcessUtils.RunAsync("nix", $"hash to-sri --type sha256 {hexHash}");
    return output.Trim();
}

// CRX file format: [Cr24 magic][version][key_len][key_len bytes][sig_len][sig_len bytes][header_size][ZIP data...]
// ZIP file format: [PK\x03\x04 magic][local file header]...
// Since CRX wraps a ZIP archive, we need to extract ZIP portion to read manifest.json
// ZIP magic: PK\x03\x04 - Phil Katz's ZIP signature (from ZIP File Format Specification by PKWARE, Inc.)
async Task<(string Version, string[] Permissions)> ExtractVersionAndPermissionsAsync(string extensionPath)
{
    // CRX magic: "Cr24" - Chrome Extension file identifier
    var crxMagic = "Cr24"u8.ToArray();
    // ZIP magic: PK\x03\x04 - Phil Katz's ZIP signature
    byte[] zipMagic = [0x50, 0x4B, 0x03, 0x04];

    await using var fileStream = File.OpenRead(extensionPath);
    var headerBytes = new byte[4];
    await fileStream.ReadExactlyAsync(headerBytes);

    string zipPath;
    if (headerBytes.SequenceEqual(crxMagic))
    {
        var allBytes = await File.ReadAllBytesAsync(extensionPath);
        var zipOffset = FindPattern(allBytes.AsSpan(), zipMagic);

        if (zipOffset < 0)
            throw new InvalidOperationException("Could not find ZIP archive within CRX file");

        zipPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.zip");
        await File.WriteAllBytesAsync(zipPath, allBytes[zipOffset..]);
    }
    else
    {
        zipPath = extensionPath;
    }

    try
    {
        await using var zip = await ZipFile.OpenReadAsync(zipPath);
        var manifestEntry = zip.GetEntry("manifest.json")
            ?? throw new InvalidOperationException("manifest.json not found in extension archive");

        await using var manifestStream = await manifestEntry.OpenAsync();
        using StreamReader reader = new(manifestStream);
        var manifestJson = await reader.ReadToEndAsync();
        using var manifest = JsonDocument.Parse(manifestJson);

        var version = manifest.RootElement.TryGetProperty("version", out var v) ? v.GetString() : null;
        if (string.IsNullOrEmpty(version) && manifest.RootElement.TryGetProperty("version_name", out var vn))
            version = vn.GetString();

        if (string.IsNullOrEmpty(version))
            throw new InvalidOperationException("Could not extract version from manifest");

        string[] permissions = [];
        if (manifest.RootElement.TryGetProperty("permissions", out var perms) && perms.ValueKind == JsonValueKind.Array)
        {
            permissions = perms.EnumerateArray()
                .Where(p => p.ValueKind == JsonValueKind.String)
                .Select(p => p.GetString()!)
                .ToArray();
        }

        var hostPermissions = new List<string>();
        if (manifest.RootElement.TryGetProperty("host_permissions", out var hostPerms) && hostPerms.ValueKind == JsonValueKind.Array)
        {
            hostPermissions.AddRange(hostPerms.EnumerateArray()
                .Where(p => p.ValueKind == JsonValueKind.String)
                .Select(p => p.GetString()!));
        }
        else if (manifest.RootElement.TryGetProperty("optional_permissions", out var optPerms) && optPerms.ValueKind == JsonValueKind.Array)
        {
            hostPermissions.AddRange(optPerms.EnumerateArray()
                .Where(p => p.ValueKind == JsonValueKind.String && p.GetString()!.Contains('/') || p.GetString()!.Contains('*'))
                .Select(p => p.GetString()!));
        }

        var allPermissions = permissions.Concat(hostPermissions).ToArray();
        return (version, allPermissions);
    }
    finally { if (zipPath != extensionPath && File.Exists(zipPath)) File.Delete(zipPath); }
}

// Searches for a byte pattern in data and returns the index of first occurrence, or -1 if not found.
// Used to locate the ZIP magic number (PK\x03\x04) within CRX files to extract the ZIP archive.
int FindPattern(ReadOnlySpan<byte> data, ReadOnlySpan<byte> pattern)
{
    for (var i = 0; i <= data.Length - pattern.Length; i++)
        if (data.Slice(i, pattern.Length).SequenceEqual(pattern))
            return i;
    return -1;
}

async Task GenerateNixFile(string outputFile, List<ExtensionResult> results, bool hasConditions, BrowserType browser)
{
    var configParam = hasConditions ? "  config," + Environment.NewLine : "";

    var unconditionalEntries = results
        .Where(r => string.IsNullOrEmpty(r.Extension.Condition) && r.NixEntry != null)
        .OrderBy(r => r.Extension.Id).ToList();
    var conditionalEntries = results
        .Where(r => !string.IsNullOrEmpty(r.Extension.Condition) && r.NixEntry != null)
        .OrderBy(r => r.Extension.Id).ToList();

    var sb = new StringBuilder();

    sb.AppendLine("# This file is auto-generated by an update script");
    sb.AppendLine("# DO NOT edit manually");

    if (browser == BrowserType.Chromium)
    {
        sb.AppendLine("{");
        sb.AppendLine("  pkgs,");
        sb.Append(configParam);
        sb.AppendLine("  lib,");
        sb.AppendLine("  ...");
        sb.AppendLine("}:");
        sb.AppendLine("lib.flatten [");

        foreach (var entry in unconditionalEntries)
            sb.AppendLine(entry.NixEntry);

        foreach (var entry in conditionalEntries)
        {
            var condition = NixEntryGenerator.Escape(entry.Extension.Condition!);
            sb.AppendLine($"  (lib.optionals ({condition}) [");
            sb.AppendLine(entry.NixEntry);
            sb.AppendLine("  ])");
        }

        sb.AppendLine("]");
    }
    else
    {
        sb.AppendLine("{ buildFirefoxXpiAddon, fetchurl, lib, stdenv }:");
        sb.AppendLine("  {");

        var entries = unconditionalEntries
            .Select(entry => $"    \"{entry.Extension.Id}\" = buildFirefoxXpiAddon {entry.NixEntry};")
            .ToList();
        entries.AddRange(from entry in conditionalEntries
                         let condition = NixEntryGenerator.Escape(entry.Extension.Condition!)
                         select $"    (lib.optionals ({condition}) [\n      buildFirefoxXpiAddon {entry.NixEntry}\n    ]);");
        foreach (var t in entries)
            sb.AppendLine(t);

        sb.AppendLine("  }");
    }

    var dir = Path.GetDirectoryName(outputFile);
    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

    await File.WriteAllTextAsync(outputFile, sb.ToString());
}

async Task ValidateNixFile(string outputFile)
{
    try { await ProcessUtils.RunAsync("nix-instantiate", $"--parse {outputFile}"); }
    catch { throw new InvalidOperationException("Generated nix file is invalid"); }
}

internal static class ProcessUtils
{
    public static async Task<string> RunAsync(string command, string arguments, string? workingDir = null)
    {
        ProcessStartInfo psi = new()
        {
            FileName = command,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            WorkingDirectory = workingDir
        };

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

    private static List<string> ParseArguments(string arguments)
    {
        var args = new List<string>();
        var current = new StringBuilder();
        var inQuotes = false;

        foreach (var c in arguments)
        {
            switch (c)
            {
                case '\'':
                    inQuotes = !inQuotes;
                    break;
                case ' ' when !inQuotes:
                    {
                        if (current.Length > 0)
                        {
                            args.Add(current.ToString());
                            current.Clear();
                        }

                        break;
                    }
                default:
                    current.Append(c);
                    break;
            }
        }

        if (current.Length > 0)
            args.Add(current.ToString());

        return args;
    }
}

internal static class GitHubUtils
{
    public static string? GetToken()
    {
        var envToken = Environment.GetEnvironmentVariable("GITHUB_TOKEN");
        if (!string.IsNullOrEmpty(envToken))
            return envToken;

        try
        {
            var ghToken = ProcessUtils.RunAsync("gh", "auth token").Result.Trim();
            if (!string.IsNullOrEmpty(ghToken) && ghToken.StartsWith("gho_"))
                return ghToken;
        }
        catch { /* ignore */ }

        return null;
    }
}

internal enum BrowserType
{
    Chromium,
    Firefox
}

internal enum ExtensionSource
{
    ChromeStore,
    Amo,
    Bpc,
    Url,
    GithubReleases
}

internal static class BrowserTypeExtensions
{
    extension(BrowserType browser)
    {
        public string GetFileExtension() =>
            browser == BrowserType.Chromium ? "crx" : "xpi";

        public bool SupportsSource(ExtensionSource source) => source switch
        {
            ExtensionSource.ChromeStore => browser == BrowserType.Chromium,
            ExtensionSource.Amo => browser == BrowserType.Firefox,
            ExtensionSource.Bpc => true,
            ExtensionSource.Url => true,
            ExtensionSource.GithubReleases => true,
            _ => false
        };
    }
}

internal readonly record struct Extension(
    string Id,
    string? Name,
    ExtensionSource Source,
    string? Url,
    string? Condition,
    string? Owner,
    string? Repo,
    string? Pattern,
    string? Version
);

internal readonly record struct GithubReleaseConfig(string? Owner, string? Repo, string? Pattern);

internal readonly record struct ExtensionResult(Extension Extension, string? Error, string? NixEntry, string? Version, string[]? Permissions);

internal readonly record struct GitHubRelease(
    [property: JsonPropertyName("tag_name")] string? TagName,
    [property: JsonPropertyName("name")] string? Name
);

[JsonSerializable(typeof(GitHubRelease))]
internal partial class GitHubReleaseContext : JsonSerializerContext;

internal readonly record struct AmoFile(
    [property: JsonPropertyName("url")] string Url
);

internal readonly record struct AmoVersion(
    [property: JsonPropertyName("file")] AmoFile? File
);

internal readonly record struct AmoAddon(
    [property: JsonPropertyName("current_version")] AmoVersion? CurrentVersion
);

[JsonSerializable(typeof(AmoFile))]
[JsonSerializable(typeof(AmoVersion))]
[JsonSerializable(typeof(AmoAddon))]
internal partial class AmoAddonContext : JsonSerializerContext;

internal class ExtensionSourceHandler(HttpClient client, HttpClient chromeStoreClient)
{
    private const string BpcRepo = "https://gitflic.ru/project/magnolia1234/bpc_uploads.git";

    public async Task<(string? Url, string? Error)> FetchUrlAsync(
        Extension ext,
        GithubReleaseConfig config,
        BrowserType browser,
        string? browserVersion,
        ProgressTask? task = null)
    {
        if (!browser.SupportsSource(ext.Source))
            return (null, $"Source '{ext.Source}' is not supported for {browser} browser");

        return ext.Source switch
        {
            ExtensionSource.ChromeStore => (await FetchChromeStoreUrlAsync(ext.Id, browserVersion, task), null),
            ExtensionSource.Amo => (await FetchAmoUrlAsync(ext.Id), null),
            ExtensionSource.Bpc => (await FetchBpcUrlAsync(browser), null),
            ExtensionSource.Url => FetchUrlSource(ext),
            ExtensionSource.GithubReleases => (await FetchGithubReleaseUrlAsync(ext, config, browser), null),
            _ => (null, $"Unknown source '{ext.Source}'")
        };
    }

    private async Task<string?> FetchChromeStoreUrlAsync(string extensionId,
        string? browserVersion,
        ProgressTask? task = null)
    {
        var prodVersion = browserVersion ?? "143";
        task?.Increment(10);

        var xParam = Uri.EscapeDataString($"id={extensionId}&installsource=ondemand&uc");

        UriBuilder uriBuilder = new("https", "clients2.google.com")
        {
            Path = "/service/update2/crx",
            Query = new StringBuilder()
                .Append("response=redirect")
                .Append("&acceptformat=crx2,crx3")
                .Append($"&prodversion={Uri.EscapeDataString(prodVersion)}")
                .Append($"&x={xParam}")
                .ToString()
        };

        var response = await chromeStoreClient.GetAsync(uriBuilder.Uri);

        return (int)response.StatusCode is 302 or 301 ? response.Headers.Location?.ToString() : null;
    }

    private async Task<string?> FetchAmoUrlAsync(string extensionSlug)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Get, $"https://addons.mozilla.org/api/v5/addons/addon/{extensionSlug}/");
            request.Headers.Add("User-Agent", "BrowserExtensionsUpdater");

            var response = await client.SendAsync(request);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();
            var addon = JsonSerializer.Deserialize(content, AmoAddonContext.Default.AmoAddon);

            if (addon.CurrentVersion is { File: not null })
                return addon.CurrentVersion.Value.File?.Url;
        }
        catch (Exception ex)
        {
            Log.Warning($"Failed to fetch AMO URL for {extensionSlug}: {ex.Message}");
        }

        return null;
    }

    private static async Task<string?> FetchBpcUrlAsync(BrowserType browser)
    {
        var filename = browser == BrowserType.Chromium
            ? "bypass-paywalls-chrome-clean-latest.crx"
            : "bypass_paywalls_clean-latest.xpi";

        var output = await ProcessUtils.RunAsync("git", $"ls-remote {BpcRepo} HEAD");
        var commit = output.Split('\t')[0];

        if (string.IsNullOrEmpty(commit))
            throw new InvalidOperationException("Failed to get latest commit for BPC");

        UriBuilder uriBuilder = new("https", "gitflic.ru")
        {
            Path = "/project/magnolia1234/bpc_uploads/blob/raw",
            Query = new StringBuilder()
                .Append($"file={Uri.EscapeDataString(filename)}")
                .Append("&inline=false")
                .Append($"&commit={Uri.EscapeDataString(commit)}")
                .ToString()
        };

        return uriBuilder.Uri.ToString();
    }

    private static (string? Url, string? Error) FetchUrlSource(Extension ext)
    {
        if (string.IsNullOrEmpty(ext.Url))
            return (null, $"Extension '{ext.Id}' has source 'url' but no 'url' field specified");
        return (ext.Url, null);
    }

    private async Task<string?> FetchGithubReleaseUrlAsync(Extension ext, GithubReleaseConfig config, BrowserType browser)
    {
        var owner = ext.Owner ??
                    config.Owner ?? throw new InvalidOperationException("GitHub release source requires 'owner' field");
        var repo = ext.Repo ??
                   config.Repo ?? throw new InvalidOperationException("GitHub release source requires 'repo' field");
        var pattern = ext.Pattern ?? config.Pattern;
        var version = ext.Version ?? "latest";

        string finalVersion;
        if (version != "latest")
        {
            finalVersion = version.TrimStart('v');
        }
        else
        {
            finalVersion = await FetchLatestGithubReleaseVersionAsync(owner, repo);
        }

        if (!string.IsNullOrEmpty(pattern))
        {
            var path = pattern
                .Replace("{version}", finalVersion)
                .Replace("{name}", ext.Id)
                .Replace("{id}", ext.Id);
            return BuildGithubUrl(owner, repo, path);
        }

        var extension = browser.GetFileExtension();
        return BuildGithubReleaseDownloadUrl(owner, repo, finalVersion, ext.Id, extension);
    }

    private async Task<string> FetchLatestGithubReleaseVersionAsync(string owner, string repo)
    {
        HttpRequestMessage request = new(HttpMethod.Get, $"https://api.github.com/repos/{owner}/{repo}/releases/latest");
        request.Headers.Add("User-Agent", "BrowserExtensionsUpdater");
        request.Headers.Add("Accept", "application/vnd.github.v3+json");

        var githubToken = GitHubUtils.GetToken();
        if (!string.IsNullOrEmpty(githubToken))
            request.Headers.Add("Authorization", $"token {githubToken}");

        var response = await client.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var content = await response.Content.ReadAsStringAsync();
        var release = JsonSerializer.Deserialize(content, GitHubReleaseContext.Default.GitHubRelease);

        var tagName = release.TagName ?? release.Name;

        return string.IsNullOrEmpty(tagName)
            ? throw new InvalidOperationException("Failed to get latest release version from GitHub API")
            : tagName.TrimStart('v');
    }

    private static string BuildGithubUrl(string owner, string repo, string path)
    {
        UriBuilder uriBuilder = new("https", "github.com")
        {
            Path = $"/{owner}/{repo}/{path}"
        };
        return uriBuilder.Uri.ToString();
    }

    private static string BuildGithubReleaseDownloadUrl(string owner,
        string repo,
        string version,
        string assetName,
        string extension)
    {
        UriBuilder uriBuilder = new("https", "github.com")
        {
            Path = $"/{owner}/{repo}/releases/download/v{version}/{assetName}.{extension}"
        };
        return uriBuilder.Uri.ToString();
    }
}

internal static class NixEntryGenerator
{
    public static string Generate(Extension ext, string url, string hash, string version, string[]? permissions, BrowserType browser)
    {
        var id = Escape(ext.Id);
        var safeUrl = Escape(url);
        var safeHash = Escape(hash);
        var safeVersion = Escape(version);

        return browser == BrowserType.Chromium
            ? GenerateChromiumEntry(id, safeUrl, safeHash, safeVersion)
            : GenerateFirefoxEntry(id, safeUrl, safeHash, safeVersion, permissions);
    }

    private static string GenerateChromiumEntry(string id, string url, string hash, string version) =>
        $$"""
          {
            id = "{{id}}";
            crxPath = pkgs.fetchurl {
              url = "{{url}}";
              name = "{{id}}.crx";
              hash = "{{hash}}";
            };
            version = "{{version}}";
          }
          """;

    private static string GenerateFirefoxEntry(string id, string url, string hash, string version, string[]? permissions)
    {
        var metaPermissions = permissions != null && permissions.Length > 0
            ? $$"""
              mozPermissions = [
                {{string.Join('\n', permissions.Select(p => $"        \"{Escape(p)}\"").ToArray())}}
              ]
              """
            : "";

        var metaContent = string.IsNullOrEmpty(metaPermissions)
            ? "platforms = platforms.all;"
            : $$"""
              platforms = platforms.all;
              {{metaPermissions.Trim()}};
              """;

        return $$"""
          {
            pname = "{{id}}";
            version = "{{version}}";
            addonId = "{{id}}";
            url = "{{url}}";
            sha256 = "{{hash}}";
            meta = with lib; {
              {{metaContent.Trim()}}
            };
          }
          """;
    }

    public static string Escape(string s) =>
        s.Replace("\\", @"\\").Replace("\"", "\\\"").Replace("$", "\\$").Replace("[", "[[").Replace("]", "]]");
}

internal static class Icons
{
    public const string Info = "\uf449";
    public const string Success = "\uf42e";
    public const string Warning = "\uf421";
    public const string Error = "\uf467";
    public const string File = "\uf471";
    public const string Chromium = "\uf268";
    public const string Firefox = "\uf269";
    public const string Extensions = "\uf40e";
}

internal static class Log
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
        s.Replace("\\", @"\\").Replace("[", "[[").Replace("]", "]]");
}
