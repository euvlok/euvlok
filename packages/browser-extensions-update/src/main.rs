use std::io::{Cursor, Read as _};
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, anyhow, bail};
use clap::Parser;
use dotfiles_common::hash;
use dotfiles_common::http::Client;
use dotfiles_common::nix;
use dotfiles_common::process::{self, argv};
use itertools::Itertools;
use serde::Deserialize;
use url::Url;

#[derive(Debug, Parser)]
#[command(
    name = "browser-extension-update",
    about = "Generate a browser extensions Nix file"
)]
struct Cli {
    /// Output Nix file. Defaults to extensions.nix in the input directory.
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Input Nix source file.
    input: PathBuf,
}

#[derive(Debug, Clone, Copy, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "kebab-case")]
enum Browser {
    Chromium,
    Firefox,
}

#[derive(Debug, Clone, Copy, Deserialize)]
#[serde(rename_all = "kebab-case")]
enum Source {
    ChromeStore,
    Amo,
    Bpc,
    Url,
    GithubReleases,
}

#[derive(Debug, Deserialize)]
struct InputFile {
    browser: Browser,
    #[serde(default)]
    extensions: Vec<Extension>,
    #[serde(default)]
    config: Config,
}

#[derive(Debug, Default, Deserialize)]
struct Config {
    #[serde(default)]
    sources: SourceConfig,
}

#[derive(Debug, Default, Deserialize)]
struct SourceConfig {
    #[serde(default, rename = "github-releases")]
    github_releases: GithubReleaseConfig,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct GithubReleaseConfig {
    owner: Option<String>,
    repo: Option<String>,
    pattern: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
struct Extension {
    id: Option<String>,
    name: Option<String>,
    #[serde(default = "default_source")]
    source: Source,
    url: Option<String>,
    condition: Option<String>,
    owner: Option<String>,
    repo: Option<String>,
    pattern: Option<String>,
    version: Option<String>,
}

#[derive(Debug)]
struct ExtensionResult {
    extension: Extension,
    nix_entry: String,
}

#[derive(Debug)]
struct ManifestInfo {
    version: String,
    permissions: Vec<String>,
    addon_id: Option<String>,
}

#[derive(Debug, Deserialize)]
struct Manifest {
    version: Option<String>,
    version_name: Option<String>,
    #[serde(default)]
    permissions: Vec<String>,
    #[serde(default)]
    optional_permissions: Vec<String>,
    #[serde(default)]
    host_permissions: Vec<String>,
    browser_specific_settings: Option<BrowserSpecificSettings>,
    applications: Option<BrowserSpecificSettings>,
}

#[derive(Debug, Deserialize)]
struct BrowserSpecificSettings {
    gecko: Option<GeckoSettings>,
}

#[derive(Debug, Deserialize)]
struct GeckoSettings {
    id: Option<String>,
}

#[derive(Debug, Deserialize)]
struct AmoAddon {
    current_version: Option<AmoVersion>,
    guid: Option<String>,
}

#[derive(Debug, Deserialize)]
struct AmoVersion {
    file: Option<AmoFile>,
}

#[derive(Debug, Deserialize)]
struct AmoFile {
    url: Option<String>,
}

#[derive(Debug, Deserialize)]
struct GithubRelease {
    tag_name: Option<String>,
    name: Option<String>,
    #[serde(default)]
    assets: Vec<GithubAsset>,
}

#[derive(Debug, Deserialize)]
struct GithubAsset {
    name: String,
    browser_download_url: String,
}

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    if !cli.input.exists() {
        bail!("input file not found: {}", cli.input.display());
    }
    let output = cli
        .output
        .unwrap_or_else(|| default_output_path(&cli.input));
    let input = parse_nix_input(&cli.input)?;
    let extensions = input
        .extensions
        .into_iter()
        .filter(|extension| {
            if extension.id.is_some() {
                true
            } else {
                eprintln!("warning: extension missing id field, skipping");
                false
            }
        })
        .collect::<Vec<_>>();
    if extensions.is_empty() {
        eprintln!("warning: no extensions found in {}", cli.input.display());
        return Ok(());
    }

    let client = Client::new("BrowserExtensionsUpdater")?;
    let chromium_version = if input.browser == Browser::Chromium {
        Some(chromium_major_version())
    } else {
        None
    };
    let results = extensions
        .into_iter()
        .map(|extension| {
            process_extension(
                &client,
                extension,
                &input.config.sources.github_releases,
                input.browser,
                chromium_version.as_deref(),
            )
        })
        .collect::<std::result::Result<Vec<_>, _>>()?;

    write_output(&output, &generate_extensions_nix(&results, input.browser))?;
    eprintln!("success: generated {}", output.display());
    Ok(())
}

fn default_source() -> Source {
    Source::ChromeStore
}

fn default_output_path(input: &Path) -> PathBuf {
    input.parent().map_or_else(
        || PathBuf::from("extensions.nix"),
        |parent| parent.join("extensions.nix"),
    )
}

fn parse_nix_input(path: &Path) -> Result<InputFile> {
    let output = process::trimmed_text(&argv([
        "nix",
        "eval",
        "--json",
        "--file",
        &path.to_string_lossy(),
    ]))
    .with_context(|| format!("failed to evaluate {}", path.display()))?;
    serde_json::from_str(&output).context("failed to parse evaluated extension input")
}

fn chromium_major_version() -> String {
    let expr = "let flake = builtins.getFlake (toString ./.); system = builtins.currentSystem; pkgs = import flake.inputs.nixpkgs { inherit system; config.allowUnfree = true; }; in pkgs.lib.strings.getVersion pkgs.chromium";
    if let Ok(output) =
        process::trimmed_text(&argv(["nix", "eval", "--raw", "--impure", "--expr", expr]))
    {
        let major = output.split('.').next().unwrap_or("143").to_owned();
        if major.bytes().all(|byte| byte.is_ascii_digit()) {
            return major;
        }
    }
    eprintln!("warning: could not determine pinned Chromium version, using default: 143");
    "143".to_owned()
}

fn process_extension(
    client: &Client,
    extension: Extension,
    config: &GithubReleaseConfig,
    browser: Browser,
    browser_version: Option<&str>,
) -> Result<ExtensionResult> {
    let id = extension_id(&extension)?;
    eprintln!(
        "info: processing {}",
        extension.name.as_deref().unwrap_or(id)
    );
    let (url, addon_id) =
        resolve_download_url(client, &extension, config, browser, browser_version)?;
    let bytes = client.bytes(&url)?;
    let hash = hash::sha256_sri(&bytes);
    let manifest = extract_manifest_info(&bytes)?;
    let addon = if browser == Browser::Firefox {
        manifest
            .addon_id
            .clone()
            .or(addon_id)
            .unwrap_or_else(|| id.to_owned())
    } else {
        id.to_owned()
    };
    let entry = generate_extension_entry(
        &extension,
        &url,
        &hash,
        &manifest.version,
        &manifest.permissions,
        browser,
        &addon,
    )?;
    Ok(ExtensionResult {
        extension,
        nix_entry: entry,
    })
}

fn extension_id(extension: &Extension) -> Result<&str> {
    extension
        .id
        .as_deref()
        .filter(|id| !id.trim().is_empty())
        .ok_or_else(|| anyhow!("extension missing id field"))
}

fn resolve_download_url(
    client: &Client,
    extension: &Extension,
    config: &GithubReleaseConfig,
    browser: Browser,
    browser_version: Option<&str>,
) -> Result<(String, Option<String>)> {
    match extension.source {
        Source::ChromeStore if browser == Browser::Chromium => Ok((
            chrome_store_url(extension_id(extension)?, browser_version)?,
            None,
        )),
        Source::Amo if browser == Browser::Firefox => amo_url(client, extension_id(extension)?),
        Source::Bpc => Ok((bpc_url(browser)?, None)),
        Source::Url => extension.url.clone().map(|url| (url, None)).ok_or_else(|| {
            anyhow!(
                "extension {} has source url but no url field",
                extension_id(extension).unwrap_or("<unknown>")
            )
        }),
        Source::GithubReleases => Ok((
            github_release_url(client, extension, config, browser)?,
            None,
        )),
        _ => bail!(
            "source {:?} is not supported for {:?}",
            extension.source,
            browser
        ),
    }
}

fn chrome_store_url(id: &str, version: Option<&str>) -> Result<String> {
    let client = Client::new_without_redirects("BrowserExtensionsUpdater")?;
    let url = chrome_store_request_url(id, version)?;
    client
        .redirect_location(url.as_str())?
        .ok_or_else(|| anyhow!("Chrome Store did not return a redirect"))
}

fn chrome_store_request_url(id: &str, version: Option<&str>) -> Result<Url> {
    let mut url = Url::parse("https://clients2.google.com/service/update2/crx")?;
    url.query_pairs_mut()
        .append_pair("response", "redirect")
        .append_pair("acceptformat", "crx2,crx3")
        .append_pair("prodversion", version.unwrap_or("143"))
        .append_pair("x", &format!("id={id}&installsource=ondemand&uc"));
    Ok(url)
}

fn amo_url(client: &Client, slug: &str) -> Result<(String, Option<String>)> {
    let url = amo_api_url(slug)?;
    let addon = client.json::<AmoAddon>(url.as_str())?;
    let url = addon
        .current_version
        .and_then(|version| version.file)
        .and_then(|file| file.url)
        .ok_or_else(|| anyhow!("AMO addon {slug} does not include a download URL"))?;
    Ok((url, addon.guid))
}

fn amo_api_url(slug: &str) -> Result<Url> {
    let mut url = Url::parse("https://addons.mozilla.org/api/v5/addons/addon")?;
    append_path_segments(&mut url, [slug, ""])?;
    Ok(url)
}

fn bpc_url(browser: Browser) -> Result<String> {
    let filename = match browser {
        Browser::Chromium => "bypass-paywalls-chrome-clean-latest.crx",
        Browser::Firefox => "bypass_paywalls_clean-latest.xpi",
    };
    let output = process::trimmed_text(&argv([
        "git",
        "ls-remote",
        "https://gitflic.ru/project/magnolia1234/bpc_uploads.git",
        "HEAD",
    ]))?;
    let commit = output
        .split_whitespace()
        .next()
        .ok_or_else(|| anyhow!("failed to get latest BPC commit"))?;
    bpc_download_url(filename, commit)
}

fn bpc_download_url(filename: &str, commit: &str) -> Result<String> {
    let mut url = Url::parse("https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw")?;
    url.query_pairs_mut()
        .append_pair("file", filename)
        .append_pair("inline", "false")
        .append_pair("commit", commit);
    Ok(url.to_string())
}

fn github_release_url(
    client: &Client,
    extension: &Extension,
    config: &GithubReleaseConfig,
    browser: Browser,
) -> Result<String> {
    let owner = extension
        .owner
        .as_ref()
        .or(config.owner.as_ref())
        .ok_or_else(|| anyhow!("GitHub release source requires owner"))?;
    let repo = extension
        .repo
        .as_ref()
        .or(config.repo.as_ref())
        .ok_or_else(|| anyhow!("GitHub release source requires repo"))?;
    let version = extension.version.as_deref().unwrap_or("latest");
    let release = if version == "latest" {
        github_get::<GithubRelease>(
            client,
            github_api_release_url(owner, repo, GithubReleaseEndpoint::Latest)?.as_str(),
        )?
    } else {
        let normalized = version.trim_start_matches('v');
        github_get::<GithubRelease>(
            client,
            github_api_release_url(
                owner,
                repo,
                GithubReleaseEndpoint::Tag(&format!("v{normalized}")),
            )?
            .as_str(),
        )
        .or_else(|_| {
            github_get::<GithubRelease>(
                client,
                github_api_release_url(owner, repo, GithubReleaseEndpoint::Tag(normalized))?
                    .as_str(),
            )
        })?
    };
    let release_version = release
        .tag_name
        .as_deref()
        .or(release.name.as_deref())
        .ok_or_else(|| anyhow!("GitHub release is missing tag/name"))?
        .trim_start_matches('v')
        .to_owned();
    if let Some(pattern) = extension.pattern.as_ref().or(config.pattern.as_ref()) {
        let path = pattern
            .replace("{version}", &release_version)
            .replace("{name}", extension_id(extension)?)
            .replace("{id}", extension_id(extension)?);
        return github_pattern_url(owner, repo, &path);
    }
    let expected = format!(
        "{}.{}",
        extension_id(extension)?,
        browser_download_extension(browser)
    );
    release
        .assets
        .into_iter()
        .find(|asset| asset.name == expected)
        .map(|asset| asset.browser_download_url)
        .ok_or_else(|| {
            anyhow!("GitHub release {release_version} does not include asset {expected}")
        })
}

fn github_get<T: for<'de> Deserialize<'de>>(client: &Client, url: &str) -> Result<T> {
    let text = if let Some(token) = github_token() {
        let response = client.get_bearer_text(url, &token)?;
        if !response.status.is_success() {
            bail!("GitHub returned status {} for {url}", response.status);
        }
        response.body
    } else {
        client.text(url)?
    };
    serde_json::from_str(&text)
        .with_context(|| format!("failed to parse GitHub response from {url}"))
}

#[derive(Debug, Clone, Copy)]
enum GithubReleaseEndpoint<'a> {
    Latest,
    Tag(&'a str),
}

fn github_api_release_url(
    owner: &str,
    repo: &str,
    endpoint: GithubReleaseEndpoint<'_>,
) -> Result<Url> {
    let mut url = Url::parse("https://api.github.com/repos")?;
    match endpoint {
        GithubReleaseEndpoint::Latest => {
            append_path_segments(&mut url, [owner, repo, "releases", "latest"])?;
        }
        GithubReleaseEndpoint::Tag(tag) => {
            append_path_segments(&mut url, [owner, repo, "releases", "tags", tag])?;
        }
    }
    Ok(url)
}

fn github_pattern_url(owner: &str, repo: &str, path: &str) -> Result<String> {
    let mut url = Url::parse("https://github.com/")?;
    append_path_segments(&mut url, [owner, repo])?;
    {
        let mut segments = url
            .path_segments_mut()
            .map_err(|()| anyhow!("GitHub URL cannot be a base"))?;
        segments.extend(path.trim_matches('/').split('/'));
    }
    Ok(url.to_string())
}

fn append_path_segments<'a>(
    url: &mut Url,
    segments: impl IntoIterator<Item = &'a str>,
) -> Result<()> {
    url.path_segments_mut()
        .map_err(|()| anyhow!("URL cannot be a base"))?
        .extend(segments);
    Ok(())
}

fn github_token() -> Option<String> {
    std::env::var("GITHUB_TOKEN")
        .ok()
        .filter(|token| !token.trim().is_empty())
        .or_else(|| {
            process::trimmed_text(&argv(["gh", "auth", "token"]))
                .ok()
                .filter(|token| !token.is_empty())
        })
}

fn browser_download_extension(browser: Browser) -> &'static str {
    match browser {
        Browser::Chromium => "crx",
        Browser::Firefox => "xpi",
    }
}

fn extract_manifest_info(bytes: &[u8]) -> Result<ManifestInfo> {
    let zip_bytes = crx_zip_contents(bytes)?;
    let cursor = Cursor::new(zip_bytes);
    let mut zip = zip::ZipArchive::new(cursor)?;
    let mut manifest_file = zip.by_name("manifest.json")?;
    let mut manifest_json = String::new();
    manifest_file.read_to_string(&mut manifest_json)?;
    let manifest = serde_json::from_str::<Manifest>(&manifest_json)?;
    let version = manifest
        .version
        .or(manifest.version_name)
        .ok_or_else(|| anyhow!("could not extract version from manifest"))?;
    let mut permissions = manifest.permissions;
    permissions.extend(if manifest.host_permissions.is_empty() {
        manifest
            .optional_permissions
            .into_iter()
            .filter(|permission| permission.contains('/') || permission.contains('*'))
            .collect()
    } else {
        manifest.host_permissions
    });
    let addon_id = manifest
        .browser_specific_settings
        .and_then(|settings| settings.gecko)
        .and_then(|gecko| gecko.id)
        .or_else(|| {
            manifest
                .applications
                .and_then(|settings| settings.gecko)
                .and_then(|gecko| gecko.id)
        });
    Ok(ManifestInfo {
        version,
        permissions,
        addon_id,
    })
}

fn crx_zip_contents(bytes: &[u8]) -> Result<Vec<u8>> {
    if bytes.len() < 4 || &bytes[0..4] != b"Cr24" {
        return Ok(bytes.to_vec());
    }
    if bytes.len() < 12 {
        bail!("invalid CRX header");
    }
    let version = u32::from_le_bytes(bytes[4..8].try_into()?);
    let offset = match version {
        2 => {
            if bytes.len() < 16 {
                bail!("invalid CRX2 header");
            }
            let public_key_len = u32::from_le_bytes(bytes[8..12].try_into()?) as usize;
            let signature_len = u32::from_le_bytes(bytes[12..16].try_into()?) as usize;
            16usize
                .checked_add(public_key_len)
                .and_then(|value| value.checked_add(signature_len))
                .ok_or_else(|| anyhow!("invalid CRX2 header length"))?
        }
        3 => {
            let header_len = u32::from_le_bytes(bytes[8..12].try_into()?) as usize;
            12usize
                .checked_add(header_len)
                .ok_or_else(|| anyhow!("invalid CRX3 header length"))?
        }
        other => bail!("unsupported CRX version {other}"),
    };
    if offset > bytes.len() {
        bail!("CRX zip offset is out of bounds");
    }
    Ok(bytes[offset..].to_vec())
}

fn generate_extension_entry(
    extension: &Extension,
    url: &str,
    hash: &str,
    version: &str,
    permissions: &[String],
    browser: Browser,
    addon: &str,
) -> Result<String> {
    let id = extension_id(extension)?;
    Ok(match browser {
        Browser::Chromium => format!(
            "  {{\n    id = {};\n    crxPath = pkgs.fetchurl {{\n      url = {};\n      name = {};\n      hash = {};\n    }};\n    version = {};\n  }}",
            nix::string_literal_escaping_dollar(id),
            nix::string_literal_escaping_dollar(url),
            nix::string_literal_escaping_dollar(&format!("{id}.crx")),
            nix::string_literal_escaping_dollar(hash),
            nix::string_literal_escaping_dollar(version)
        ),
        Browser::Firefox => {
            let meta = if permissions.is_empty() {
                "platforms = platforms.all;".to_owned()
            } else {
                format!(
                    "platforms = platforms.all;\n      mozPermissions = [\n{}\n      ];",
                    permissions
                        .iter()
                        .map(|permission| {
                            format!(
                                "        {}",
                                nix::string_literal_escaping_dollar(permission)
                            )
                        })
                        .join("\n")
                )
            };
            format!(
                "  {{\n    pname = {};\n    version = {};\n    addonId = {};\n    url = {};\n    sha256 = {};\n    meta = with lib; {{\n      {meta}\n    }};\n  }}",
                nix::string_literal_escaping_dollar(id),
                nix::string_literal_escaping_dollar(version),
                nix::string_literal_escaping_dollar(addon),
                nix::string_literal_escaping_dollar(url),
                nix::string_literal_escaping_dollar(hash)
            )
        }
    })
}

fn generate_extensions_nix(results: &[ExtensionResult], browser: Browser) -> String {
    let mut plain = results
        .iter()
        .filter(|result| result.extension.condition.is_none())
        .collect::<Vec<_>>();
    let mut gated = results
        .iter()
        .filter(|result| result.extension.condition.is_some())
        .collect::<Vec<_>>();
    plain.sort_by_key(|result| result.extension.id.as_deref().unwrap_or_default());
    gated.sort_by_key(|result| result.extension.id.as_deref().unwrap_or_default());

    let conditional = !gated.is_empty();
    let mut lines = vec![
        "# This file is auto-generated by an update script".to_owned(),
        "# DO NOT edit manually".to_owned(),
    ];
    match browser {
        Browser::Chromium => {
            lines.extend(["{".into(), "  pkgs,".into()]);
            if conditional {
                lines.push("  config,".into());
            }
            lines.extend([
                "  lib,".into(),
                "  ...".into(),
                "}:".into(),
                "lib.lists.flatten [".into(),
            ]);
            lines.extend(plain.into_iter().map(|result| result.nix_entry.clone()));
            for result in gated {
                if let Some(condition) = &result.extension.condition {
                    lines.push(format!(
                        "  (lib.lists.optionals ({}) [",
                        nix::escape_string_and_dollar(condition)
                    ));
                    lines.push(result.nix_entry.clone());
                    lines.push("  ])".into());
                }
            }
            lines.push("]".into());
        }
        Browser::Firefox => {
            lines.extend([
                "{ buildFirefoxXpiAddon, fetchurl, lib, stdenv }:".into(),
                "  {".into(),
            ]);
            for result in plain {
                if let Ok(id) = extension_id(&result.extension) {
                    lines.push(format!(
                        "    \"{}\" = buildFirefoxXpiAddon {};",
                        nix::escape_string_and_dollar(id),
                        result.nix_entry
                    ));
                }
            }
            lines.push("  }".into());
        }
    }
    format!("{}\n", lines.join("\n"))
}

fn write_output(path: &Path, content: &str) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs_err::create_dir_all(parent)?;
    }
    fs_err::write(path, content)?;
    let _ = process::run(&argv([
        "nix",
        "run",
        "nixpkgs#nixfmt",
        "--",
        &path.to_string_lossy(),
    ]));
    process::run(&argv([
        "nix-instantiate",
        "--parse",
        &path.to_string_lossy(),
    ]))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generates_chromium_nix_entries() -> Result<()> {
        let extension = Extension {
            id: Some("abc".into()),
            name: None,
            source: Source::Url,
            url: None,
            condition: None,
            owner: None,
            repo: None,
            pattern: None,
            version: None,
        };
        let entry = generate_extension_entry(
            &extension,
            "https://example.test/a.crx",
            "sha256-test",
            "1.0",
            &[],
            Browser::Chromium,
            "abc",
        )?;
        assert!(entry.contains("id = \"abc\";"));
        assert!(entry.contains("version = \"1.0\";"));
        Ok(())
    }

    #[test]
    fn parses_manifest_info() -> Result<()> {
        let cursor = Cursor::new(Vec::<u8>::new());
        let mut writer = zip::ZipWriter::new(cursor);
        writer.start_file("manifest.json", zip::write::SimpleFileOptions::default())?;
        std::io::Write::write_all(
            &mut writer,
            br#"{"version":"1.2.3","permissions":["tabs"],"host_permissions":["*://example.test/*"]}"#,
        )?;
        let bytes = writer.finish()?.into_inner();
        let manifest = extract_manifest_info(&bytes)?;
        assert_eq!(manifest.version, "1.2.3");
        assert_eq!(manifest.permissions, ["tabs", "*://example.test/*"]);
        Ok(())
    }

    #[test]
    fn builds_chrome_store_request_url_with_nested_query() -> Result<()> {
        let url = chrome_store_request_url("abc", Some("144"))?;

        assert_eq!(url.host_str(), Some("clients2.google.com"));
        assert_eq!(
            url.query_pairs()
                .find(|(name, _)| name == "prodversion")
                .map(|(_, value)| value.into_owned()),
            Some("144".to_owned())
        );
        assert_eq!(
            url.query_pairs()
                .find(|(name, _)| name == "x")
                .map(|(_, value)| value.into_owned()),
            Some("id=abc&installsource=ondemand&uc".to_owned())
        );
        Ok(())
    }

    #[test]
    fn builds_source_urls_with_url_builder() -> Result<()> {
        assert_eq!(
            amo_api_url("ublock-origin")?.as_str(),
            "https://addons.mozilla.org/api/v5/addons/addon/ublock-origin/"
        );
        assert_eq!(
            bpc_download_url("bypass.xpi", "abc123")?,
            "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass.xpi&inline=false&commit=abc123"
        );
        assert_eq!(
            github_api_release_url("owner", "repo", GithubReleaseEndpoint::Tag("v1.2.3"))?.as_str(),
            "https://api.github.com/repos/owner/repo/releases/tags/v1.2.3"
        );
        assert_eq!(
            github_pattern_url("owner", "repo", "releases/download/v1.2.3/addon.xpi")?,
            "https://github.com/owner/repo/releases/download/v1.2.3/addon.xpi"
        );
        Ok(())
    }

    #[test]
    fn generates_conditional_chromium_file() {
        let results = vec![ExtensionResult {
            extension: Extension {
                id: Some("abc".into()),
                name: None,
                source: Source::Url,
                url: None,
                condition: Some("config.catppuccin.enable".into()),
                owner: None,
                repo: None,
                pattern: None,
                version: None,
            },
            nix_entry: "  { id = \"abc\"; }".into(),
        }];
        let nix = generate_extensions_nix(&results, Browser::Chromium);
        assert!(nix.contains("config,"));
        assert!(nix.contains("lib.lists.optionals"));
    }
}
