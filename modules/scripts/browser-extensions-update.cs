#!/usr/bin/dotnet run

#:package System.CommandLine@2.0.3
#:package Spectre.Console@0.54.1-alpha.0.68
#:package CliWrap@3.10.0
#:property Nullable=enable

using System.CommandLine;
using System.IO.Compression;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using CliWrap;
using CliWrap.Buffered;
using Spectre.Console;

var handler = new SocketsHttpHandler { PooledConnectionLifetime = TimeSpan.FromMinutes(2) };
HttpClient client = new(handler);
var chromeStoreHandler = new SocketsHttpHandler { PooledConnectionLifetime = TimeSpan.FromMinutes(2), AllowAutoRedirect = false };
HttpClient chromeStoreClient = new(chromeStoreHandler);

Option<string> inputOpt = new("--input", "-i")
{
    Description = "Specify the input Nix source file",
    Required = true
};
Option<string> outputOpt = new("--output", "-o")
{
    Description = "Specify the output Nix file (default: extensions.nix in the same directory)",
    Required = false
};
RootCommand root = new("Generates a Nix file for browser extensions from a Nix source file")
{
    inputOpt,
    outputOpt
};

root.SetAction(async (parseResult, ct) =>
{
    try
    {
        var inputFile = parseResult.GetValue(inputOpt)!;
        var outputFile = parseResult.GetValue(outputOpt) ?? Path.Combine(Path.GetDirectoryName(inputFile)!, "extensions.nix");

        if (!File.Exists(inputFile))
        {
            Log.Error($"Input file not found: {inputFile}");
            return 1;
        }

        AnsiConsole.Write(new FigletText("Extensions").Color(Color.Blue));
        Log.Header($"{Icons.File} {inputFile}");
        Log.Info($"Output: {outputFile}");

        var (extensions, config, hasConditions, browser) = await ParseNixInput(inputFile, ct);
        Log.Info($"Browser: {browser}");
        if (extensions.Count is 0)
        {
            Log.Warning($"No extensions found in {inputFile}");
            return 0;
        }

        Log.Info($"Found {extensions.Count} extension(s) to process");

        string? browserVersion = null;
        if (browser == BrowserType.Chromium)
        {
            browserVersion = await GetChromiumMajorVersionAsync(null, ct);
            Log.Info($"{Icons.Chromium} Chromium version: {browserVersion}");
        }
        else
        {
            Log.Info($"{Icons.Firefox} Firefox extensions");
        }

        var results = await ProcessExtensionsWithProgress(extensions, config, browser, browserVersion, ct);
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
        await Cli.Wrap("nix").WithArguments(["run", "nixpkgs#nixfmt", "--", outputFile]).ExecuteAsync(ct);
        await ValidateNixFile(outputFile, ct);

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

async Task<(List<Extension> Extensions, GithubReleaseConfig Config, bool HasConditions, BrowserType Browser)>
    ParseNixInput(string inputFile,
        CancellationToken ct = default)
{
    var json = (await Cli.Wrap("nix")
        .WithArguments([
            "eval",
            "--json",
            "--file",
            inputFile
        ])
        .ExecuteBufferedAsync(ct)).StandardOutput;
    var nixInput = JsonSerializer.Deserialize(json, AppJsonContext.Default.NixInputFile)
        ?? throw new InvalidOperationException("Failed to parse Nix input file");

    if (string.IsNullOrEmpty(nixInput.Browser) || !Enum.TryParse<BrowserType>(nixInput.Browser, true, out var browser))
        throw new InvalidOperationException(
            $"Invalid or missing 'browser' field in {inputFile}. Must be 'chromium' or 'firefox'.");

    List<Extension> extensions = [];
    var hasConditions = false;

    var ghConfig = new GithubReleaseConfig(
        nixInput.Config?.Sources?.GithubReleases?.Owner,
        nixInput.Config?.Sources?.GithubReleases?.Repo,
        nixInput.Config?.Sources?.GithubReleases?.Pattern);

    foreach (var nixExt in nixInput.Extensions)
    {
        if (string.IsNullOrEmpty(nixExt.Id))
        {
            Log.Warning("Extension missing 'id' field, skipping");
            continue;
        }

        if (!string.IsNullOrEmpty(nixExt.Condition)) hasConditions = true;

        var sourceStr = nixExt.Source ?? "chrome-store";
        if (!Enum.TryParse<ExtensionSource>(sourceStr.Replace("-", ""), true, out var source))
        {
            Log.Warning($"Unknown source '{sourceStr}' for extension '{nixExt.Id}', defaulting to ChromeStore");
            source = ExtensionSource.ChromeStore;
        }

        extensions.Add(new Extension(
            Id: nixExt.Id,
            Name: nixExt.Name,
            Source: source,
            Url: nixExt.Url,
            Condition: nixExt.Condition,
            Owner: nixExt.Owner,
            Repo: nixExt.Repo,
            Pattern: nixExt.Pattern,
            Version: nixExt.Version));
    }

    return (extensions, ghConfig, hasConditions, browser);
}

async Task<List<ExtensionResult>> ProcessExtensionsWithProgress(List<Extension> extensions,
    GithubReleaseConfig config,
    BrowserType browser,
    string? browserVersion,
    CancellationToken ct = default)
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
            await Parallel.ForEachAsync(extensions,
                new ParallelOptions
                {
                    MaxDegreeOfParallelism = 5,
                    CancellationToken = ct
                },
                async (ext,
                    token) =>
            {
                var task = ctx.AddTask(ext.Name ?? ext.Id, maxValue: 100);
                try
                {
                    var result = await ProcessExtensionQuiet(ext, config, browser, browserVersion, task, token);
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
                }
            });
        });

    return results;
}

async Task<ExtensionResult> ProcessExtensionQuiet(Extension ext,
    GithubReleaseConfig config,
    BrowserType browser,
    string? browserVersion,
    ProgressTask? task = null,
    CancellationToken ct = default)
{
    try
    {
        task?.Increment(10);

        var sourceHandler = new ExtensionSourceHandler(client, chromeStoreClient);
        var (finalUrl, error, amoAddonId) = await sourceHandler.FetchUrlAsync(ext,
            config,
            browser,
            browserVersion,
            task,
            ct);

        if (error != null)
            return new ExtensionResult(ext, error, null, null);

        if (string.IsNullOrEmpty(finalUrl))
            return new ExtensionResult(ext, "Failed to get download URL", null, null);

        task?.Increment(20);

        var extension = browser.GetFileExtension();
        var tempFile = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.{extension}");
        try
        {
            await using var stream = await client.GetStreamAsync(finalUrl, ct);
            await using var fileStream = File.Create(tempFile);
            await stream.CopyToAsync(fileStream, ct);
        }
        catch (Exception ex)
        {
            return new ExtensionResult(ext, $"Failed to download: {ex.Message}", null, null);
        }

        task?.Increment(40);

        try
        {
            var hash = await CalculateNixHashAsync(tempFile, ct);
            task?.Increment(20);
            var (version,
                permissions, 
                manifestAddonId) = await ExtractVersionAndPermissionsAsync(tempFile);
            task?.Increment(10);

            // For Firefox: resolve the real addon ID
            // Priority: manifest gecko ID > AMO guid > source slug
            var resolvedAddonId = browser == BrowserType.Firefox
                ? manifestAddonId ?? amoAddonId ?? ext.Id
                : null;

            if (browser == BrowserType.Firefox && resolvedAddonId != ext.Id)
                Log.Info($"Resolved addonId for {ext.Id}: {resolvedAddonId}");

            var nixEntry = NixEntryGenerator.Generate(ext,
                finalUrl,
                hash,
                version,
                permissions,
                browser,
                resolvedAddonId);
            return new ExtensionResult(ext, null, nixEntry, version);
        }
        finally
        {
            if (File.Exists(tempFile)) File.Delete(tempFile);
        }
    }
    catch (Exception ex)
    {
        return new ExtensionResult(ext, ex.Message, null, null);
    }
}

async Task<string> GetChromiumMajorVersionAsync(string? cachedVersion, CancellationToken ct = default)
{
    if (cachedVersion != null)
        return cachedVersion;

    try
    {
        var output = (await Cli.Wrap("nix")
            .WithArguments([
                "eval",
                "--impure",
                "--expr",
                "with import <nixpkgs> {}; lib.getVersion chromium"
            ])
            .ExecuteBufferedAsync(ct)).StandardOutput;
        var version = output.Trim().Trim('"').Split('.')[0];
        if (int.TryParse(version, out _))
            return version;
    }
    catch { /* ignore */ }

    Log.Warning("Could not determine Chromium version, using default: 143");
    return "143";
}

async Task<string> CalculateNixHashAsync(string filePath, CancellationToken ct = default)
{
    await using var stream = File.OpenRead(filePath);
    var hash = await SHA256.HashDataAsync(stream, ct);
    var hexHash = Convert.ToHexStringLower(hash);

    var output = (await Cli.Wrap("nix")
        .WithArguments([
            "hash",
            "to-sri",
            "--type",
            "sha256",
            hexHash
        ])
        .ExecuteBufferedAsync(ct)).StandardOutput;
    return output.Trim();
}

// CRX file format: [Cr24 magic][version][key_len][key_len bytes][sig_len][sig_len bytes][header_size][ZIP data...]
// ZIP file format: [PK\x03\x04 magic][local file header]...
// Since CRX wraps a ZIP archive, we need to extract ZIP portion to read manifest.json
// ZIP magic: PK\x03\x04 - Phil Katz's ZIP signature (from ZIP File Format Specification by PKWARE, Inc.)
async Task<(string Version, string[] Permissions, string? AddonId)> ExtractVersionAndPermissionsAsync(
    string extensionPath)
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
        var zipOffset = allBytes.AsSpan().IndexOf(zipMagic);

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

        List<string> hostPermissions = [];
        if (manifest.RootElement.TryGetProperty("host_permissions",
                out var hostPerms) &&
            hostPerms.ValueKind == JsonValueKind.Array)
        {
            hostPermissions.AddRange(hostPerms.EnumerateArray()
                .Where(p => p.ValueKind == JsonValueKind.String)
                .Select(p => p.GetString()!));
        }
        else if (manifest.RootElement.TryGetProperty("optional_permissions",
                     out var optPerms) &&
                 optPerms.ValueKind == JsonValueKind.Array)
        {
            hostPermissions.AddRange(optPerms.EnumerateArray()
                .Where(p => p.ValueKind == JsonValueKind.String &&
                            (p.GetString()!.Contains('/') || p.GetString()!.Contains('*')))
                .Select(p => p.GetString()!));
        }

        var allPermissions = permissions.Concat(hostPermissions).ToArray();

        // Extract Firefox addon ID from manifest.json
        string? addonId = null;
        if (manifest.RootElement.TryGetProperty("browser_specific_settings", out var bss)
            && bss.TryGetProperty("gecko", out var gecko)
            && gecko.TryGetProperty("id", out var geckoId))
        {
            addonId = geckoId.GetString();
        }
        else if (manifest.RootElement.TryGetProperty("applications", out var apps)
            && apps.TryGetProperty("gecko", out var geckoLegacy)
            && geckoLegacy.TryGetProperty("id", out var geckoIdLegacy))
        {
            addonId = geckoIdLegacy.GetString();
        }

        return (version, allPermissions, addonId);
    }
    finally { if (zipPath != extensionPath && File.Exists(zipPath)) File.Delete(zipPath); }
}

async Task GenerateNixFile(string outputFile, List<ExtensionResult> results, bool hasConditions, BrowserType browser)
{
    var configParam = hasConditions ? "  config," + Environment.NewLine : "";

    var unconditionalEntries = results
        .Where(r => string.IsNullOrEmpty(r.Extension.Condition) && r.NixEntry != null)
        .OrderBy(r => r.Extension.Id)
        .ToList();
    var conditionalEntries = results
        .Where(r => !string.IsNullOrEmpty(r.Extension.Condition) && r.NixEntry != null)
        .OrderBy(r => r.Extension.Id)
        .ToList();

    StringBuilder sb = new();

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

async Task ValidateNixFile(string outputFile, CancellationToken ct = default)
{
    try { await Cli.Wrap("nix-instantiate").WithArguments(["--parse", outputFile]).ExecuteAsync(ct); }
    catch { throw new InvalidOperationException("Generated nix file is invalid"); }
}

internal static class GitHubUtils
{
    public static async Task<string?> GetTokenAsync(CancellationToken ct = default)
    {
        var envToken = Environment.GetEnvironmentVariable("GITHUB_TOKEN");
        if (!string.IsNullOrEmpty(envToken))
            return envToken;

        try
        {
            var ghToken = (await Cli.Wrap("gh").WithArguments(["auth", "token"]).ExecuteBufferedAsync(ct)).StandardOutput.Trim();
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

internal readonly record struct ExtensionResult(Extension Extension, string? Error, string? NixEntry, string? Version);

internal readonly record struct GitHubRelease(
    [property: JsonPropertyName("tag_name")] string? TagName,
    [property: JsonPropertyName("name")] string? Name
);

internal record NixInputFile(
    [property: JsonPropertyName("browser")] string? Browser,
    [property: JsonPropertyName("extensions")] NixInputExtension[] Extensions,
    [property: JsonPropertyName("config")] NixInputConfig? Config = null
);

internal record NixInputExtension(
    [property: JsonPropertyName("id")] string? Id,
    [property: JsonPropertyName("name")] string? Name = null,
    [property: JsonPropertyName("source")] string? Source = null,
    [property: JsonPropertyName("url")] string? Url = null,
    [property: JsonPropertyName("condition")] string? Condition = null,
    [property: JsonPropertyName("owner")] string? Owner = null,
    [property: JsonPropertyName("repo")] string? Repo = null,
    [property: JsonPropertyName("pattern")] string? Pattern = null,
    [property: JsonPropertyName("version")] string? Version = null
);

internal record NixInputConfig(
    [property: JsonPropertyName("sources")] NixInputSources? Sources = null
);

internal record NixInputSources(
    [property: JsonPropertyName("github-releases")] NixInputGithubReleases? GithubReleases = null
);

internal record NixInputGithubReleases(
    [property: JsonPropertyName("owner")] string? Owner = null,
    [property: JsonPropertyName("repo")] string? Repo = null,
    [property: JsonPropertyName("pattern")] string? Pattern = null
);

internal readonly record struct AmoFile([property: JsonPropertyName("url")] string Url);
internal readonly record struct AmoVersion([property: JsonPropertyName("file")] AmoFile? File);
internal readonly record struct AmoAddon(
    [property: JsonPropertyName("current_version")]
    AmoVersion? CurrentVersion,
    [property: JsonPropertyName("guid")] string? Guid);

[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.SnakeCaseLower)]
[JsonSerializable(typeof(NixInputFile))]
[JsonSerializable(typeof(GitHubRelease))]
[JsonSerializable(typeof(AmoAddon))]
internal partial class AppJsonContext : JsonSerializerContext;

internal class ExtensionSourceHandler(HttpClient client, HttpClient chromeStoreClient)
{
    private const string BpcRepo = "https://gitflic.ru/project/magnolia1234/bpc_uploads.git";

    public async Task<(string? Url, string? Error, string? AddonId)> FetchUrlAsync(
        Extension ext,
        GithubReleaseConfig config,
        BrowserType browser,
        string? browserVersion,
        ProgressTask? task = null,
        CancellationToken ct = default)
    {
        if (!browser.SupportsSource(ext.Source))
            return (null, $"Source '{ext.Source}' is not supported for {browser} browser", null);

        return ext.Source switch
        {
            ExtensionSource.ChromeStore => (await FetchChromeStoreUrlAsync(ext.Id, browserVersion, task, ct), null, null),
            ExtensionSource.Amo => await FetchAmoUrlAndGuidAsync(ext.Id, ct),
            ExtensionSource.Bpc => (await FetchBpcUrlAsync(browser, ct), null, null),
            ExtensionSource.Url => FetchUrlSource(ext) is var result ? (result.Url, result.Error, null) : default,
            ExtensionSource.GithubReleases => (await FetchGithubReleaseUrlAsync(ext, config, browser, ct), null, null),
            _ => (null, $"Unknown source '{ext.Source}'", null)
        };
    }

    private async Task<string?> FetchChromeStoreUrlAsync(string extensionId,
        string? browserVersion,
        ProgressTask? task = null,
        CancellationToken ct = default)
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

        var response = await chromeStoreClient.GetAsync(uriBuilder.Uri, ct);

        return (int)response.StatusCode is 302 or 301 ? response.Headers.Location?.ToString() : null;
    }

    private async Task<(string? Url, string? Error, string? AddonId)> FetchAmoUrlAndGuidAsync(string extensionSlug,
        CancellationToken ct = default)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Get, $"https://addons.mozilla.org/api/v5/addons/addon/{extensionSlug}/");
            request.Headers.Add("User-Agent", "BrowserExtensionsUpdater");

            var response = await client.SendAsync(request, ct);
            response.EnsureSuccessStatusCode();

            var addon = await response.Content.ReadFromJsonAsync(AppJsonContext.Default.AmoAddon, ct);

            var url = addon.CurrentVersion?.File?.Url;
            var guid = addon.Guid;

            return (url, null, guid);
        }
        catch (Exception ex)
        {
            Log.Warning($"Failed to fetch AMO data for {extensionSlug}: {ex.Message}");
            return (null, ex.Message, null);
        }
    }

    private static async Task<string?> FetchBpcUrlAsync(BrowserType browser, CancellationToken ct = default)
    {
        var filename = browser == BrowserType.Chromium
            ? "bypass-paywalls-chrome-clean-latest.crx"
            : "bypass_paywalls_clean-latest.xpi";

        var output = (await Cli.Wrap("git")
            .WithArguments([
                "ls-remote",
                BpcRepo,
                "HEAD"
            ])
            .ExecuteBufferedAsync(ct)).StandardOutput;
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

    private async Task<string?> FetchGithubReleaseUrlAsync(Extension ext,
        GithubReleaseConfig config,
        BrowserType browser,
        CancellationToken ct = default)
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
            finalVersion = await FetchLatestGithubReleaseVersionAsync(owner, repo, ct);
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

    private async Task<string> FetchLatestGithubReleaseVersionAsync(string owner,
        string repo,
        CancellationToken ct = default)
    {
        HttpRequestMessage request = new(HttpMethod.Get, $"https://api.github.com/repos/{owner}/{repo}/releases/latest");
        request.Headers.Add("User-Agent", "BrowserExtensionsUpdater");
        request.Headers.Add("Accept", "application/vnd.github.v3+json");

        var githubToken = await GitHubUtils.GetTokenAsync(ct);
        if (!string.IsNullOrEmpty(githubToken))
            request.Headers.Add("Authorization", $"token {githubToken}");

        var response = await client.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();

        var release = await response.Content.ReadFromJsonAsync(AppJsonContext.Default.GitHubRelease, ct);

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
    public static string Generate(Extension ext, string url, string hash, string version,
        string[]? permissions, BrowserType browser, string? resolvedAddonId = null)
    {
        var id = Escape(ext.Id);
        var safeUrl = Escape(url);
        var safeHash = Escape(hash);
        var safeVersion = Escape(version);

        return browser == BrowserType.Chromium
            ? GenerateChromiumEntry(id, safeUrl, safeHash, safeVersion)
            : GenerateFirefoxEntry(id, safeUrl, safeHash, safeVersion, permissions,
                Escape(resolvedAddonId ?? ext.Id));
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

    private static string GenerateFirefoxEntry(string id, string url, string hash, string version,
        string[]? permissions, string addonId)
    {
        var metaPermissions = permissions is { Length: > 0 }
            ? $"""
              mozPermissions = [
                {string.Join('\n', permissions.Select(p => $"        \"{Escape(p)}\"").ToArray())}
              ]
              """
            : "";

        var metaContent = string.IsNullOrEmpty(metaPermissions)
            ? "platforms = platforms.all;"
            : $"""
              platforms = platforms.all;
              {metaPermissions.Trim()};
              """;

        return $$"""
          {
            pname = "{{id}}";
            version = "{{version}}";
            addonId = "{{addonId}}";
            url = "{{url}}";
            sha256 = "{{hash}}";
            meta = with lib; {
              {{metaContent.Trim()}}
            };
          }
          """;
    }

    public static string Escape(string s) =>
        s.Replace("\\", @"\\").Replace("\"", "\\\"").Replace("$", "\\$");
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
