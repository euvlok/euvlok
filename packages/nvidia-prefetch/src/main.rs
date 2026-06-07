use std::io::Read as _;
use std::path::PathBuf;

use clap::{ArgAction, Parser};
use dotfiles_common::hash;
use dotfiles_common::http::Client;
use dotfiles_common::nix;
use dotfiles_common::{fs, process};
use semver::Version;
use sha2::{Digest as _, Sha256};

const X86_64_BASE_URL: &str = "https://download.nvidia.com/XFree86/Linux-x86_64";
const AARCH64_BASE_URL: &str = "https://download.nvidia.com/XFree86/Linux-aarch64";
const GITHUB_BASE_URL: &str = "https://github.com/NVIDIA";
const NVIDIA_DRIVER_FILE: &str = "modules/nixos/nvidia-driver.nix";

#[derive(Debug, Parser)]
#[command(
    name = "nvidia-prefetch",
    about = "Fetch NVIDIA driver hashes and optionally update nvidia-driver.nix"
)]
struct Options {
    /// Update modules/nixos/nvidia-driver.nix after fetching hashes.
    #[arg(long, action = ArgAction::SetTrue, conflicts_with = "no_update")]
    update: bool,

    /// Print hashes without updating modules/nixos/nvidia-driver.nix.
    #[arg(long, action = ArgAction::SetTrue)]
    no_update: bool,

    /// Driver version to fetch. Defaults to the latest version shared by x86_64 and aarch64.
    requested_version: Option<String>,
}

impl Options {
    fn should_update(&self) -> bool {
        self.update || !self.no_update
    }
}

#[derive(Debug)]
struct DriverHashes {
    sha256: String,
    sha256_aarch64: String,
    open_sha256: String,
    settings_sha256: String,
    persistenced_sha256: String,
}

#[derive(Debug, Clone, Eq, PartialEq)]
struct NvidiaVersion {
    raw: String,
    semver: Version,
}

impl NvidiaVersion {
    fn parse(raw: &str) -> Option<Self> {
        Some(Self {
            raw: raw.to_owned(),
            semver: parse_nvidia_version(raw)?,
        })
    }

    fn as_str(&self) -> &str {
        &self.raw
    }
}

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn std::error::Error>> {
    let options = Options::parse();
    let client = Client::new("nvidia-prefetch")?;
    let driver_version = match &options.requested_version {
        Some(version) => version.clone(),
        None => {
            let version = fetch_latest(&client)?;
            eprintln!("success: Using latest driver version: {version}");
            version
        }
    };

    exit_if_current(options.should_update(), &driver_version)?;

    let hashes = fetch_all(&client, &driver_version)?;
    log_hashes(&hashes);
    if options.should_update() {
        update_nix_file(&driver_version, &hashes)?;
    }

    Ok(())
}

fn fetch_latest(client: &Client) -> Result<String, Box<dyn std::error::Error>> {
    eprintln!("info: Fetching latest NVIDIA driver version from all platforms...");
    let x86 = fetch_platform_versions(client, X86_64_BASE_URL, "x86_64")?;
    let aarch64 = fetch_platform_versions(client, AARCH64_BASE_URL, "aarch64")?;
    latest_shared(&x86, &aarch64)
        .map(ToOwned::to_owned)
        .ok_or_else(|| "no shared NVIDIA driver version found".into())
}

fn fetch_platform_versions(
    client: &Client,
    base_url: &str,
    name: &str,
) -> Result<Vec<NvidiaVersion>, Box<dyn std::error::Error>> {
    eprintln!("info: Checking {name} platform...");
    let body = client.text(&format!("{base_url}/"))?;
    let versions = parse_versions_from_index(&body);
    if versions.is_empty() {
        return Err(format!("no NVIDIA versions found for {name}").into());
    }
    Ok(versions)
}

fn parse_versions_from_index(html: &str) -> Vec<NvidiaVersion> {
    let mut versions = Vec::new();
    let mut rest = html;
    while let Some(start) = rest.find("href=") {
        rest = &rest[start + "href=".len()..];
        let Some(quote) = rest.as_bytes().first().copied() else {
            break;
        };
        if quote != b'\'' && quote != b'"' {
            rest = &rest[1..];
            continue;
        }
        let value = &rest[1..];
        let Some(end) = value.find(char::from(quote)) else {
            break;
        };
        let candidate = value[..end].trim_matches('/');
        if let Some(version) = NvidiaVersion::parse(candidate) {
            versions.push(version);
        }
        rest = &value[end + 1..];
    }
    versions.sort_by(|left, right| left.semver.cmp(&right.semver));
    versions
}

fn is_valid_version(version: &str) -> bool {
    !version.is_empty()
        && version.contains('.')
        && !version.starts_with('.')
        && !version.ends_with('.')
        && version
            .bytes()
            .all(|byte| byte.is_ascii_digit() || byte == b'.')
        && !version.contains("..")
}

fn parse_nvidia_version(version: &str) -> Option<Version> {
    if !is_valid_version(version) {
        return None;
    }
    let mut components = version
        .split('.')
        .map(|part| part.parse::<u64>())
        .collect::<Result<Vec<_>, _>>()
        .ok()?;
    if components.len() > 3 {
        return None;
    }
    components.resize(3, 0);
    Version::parse(&format!(
        "{}.{}.{}",
        components[0], components[1], components[2]
    ))
    .ok()
}

fn latest_shared<'a>(left: &'a [NvidiaVersion], right: &[NvidiaVersion]) -> Option<&'a str> {
    let right = right
        .iter()
        .map(|version| &version.semver)
        .collect::<std::collections::HashSet<_>>();
    left.iter()
        .filter(|version| right.contains(&version.semver))
        .max_by(|left, right| left.semver.cmp(&right.semver))
        .map(NvidiaVersion::as_str)
}

fn exit_if_current(update: bool, driver_version: &str) -> Result<(), Box<dyn std::error::Error>> {
    if !update {
        return Ok(());
    }
    let Some(current) = current_version()? else {
        return Ok(());
    };
    let Some(requested_version) = parse_nvidia_version(driver_version) else {
        return Err(format!("invalid NVIDIA driver version: {driver_version}").into());
    };
    let Some(current_version) = parse_nvidia_version(&current) else {
        return Err(format!(
            "invalid current NVIDIA driver version in {NVIDIA_DRIVER_FILE}: {current}"
        )
        .into());
    };
    if requested_version < current_version {
        eprintln!(
            "Refusing to downgrade NVIDIA driver from {current} to {driver_version}. Specify a version manually if this downgrade is intentional."
        );
        std::process::exit(1);
    }
    if current == driver_version {
        eprintln!("info: Current version ({current}) is already up to date");
        eprintln!("info: Use --no-update to force hash recalculation");
        std::process::exit(0);
    }
    Ok(())
}

fn fetch_all(
    client: &Client,
    driver_version: &str,
) -> Result<DriverHashes, Box<dyn std::error::Error>> {
    eprintln!("info: Fetching hashes for NVIDIA driver version {driver_version}...");
    Ok(DriverHashes {
        sha256: fetch_driver_hash(client, "x86_64", X86_64_BASE_URL, driver_version)?,
        sha256_aarch64: fetch_driver_hash(client, "aarch64", AARCH64_BASE_URL, driver_version)?,
        open_sha256: prefetch_github_source_hash(
            client,
            "open-gpu-kernel-modules",
            driver_version,
        )?,
        settings_sha256: prefetch_github_source_hash(client, "nvidia-settings", driver_version)?,
        persistenced_sha256: prefetch_github_source_hash(
            client,
            "nvidia-persistenced",
            driver_version,
        )?,
    })
}

fn fetch_driver_hash(
    client: &Client,
    arch: &str,
    base_url: &str,
    driver_version: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let driver_name = format!("NVIDIA-Linux-{arch}-{driver_version}.run");
    let url = format!("{base_url}/{driver_version}/{driver_name}");
    eprintln!("info: Fetching {arch} driver {driver_version}...");
    let mut reader = client.reader(&url)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0; 1024 * 1024];
    loop {
        let read = reader.read(&mut buffer)?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(hash::sri_from_sha256_digest(hasher.finalize().as_slice()))
}

fn prefetch_github_source_hash(
    client: &Client,
    repo: &str,
    driver_version: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    eprintln!("info: Fetching {repo}...");
    let url = format!("{GITHUB_BASE_URL}/{repo}/archive/{driver_version}.tar.gz");
    let temp_dir = fs::tmp_dir("nvidia-prefetch-")?;
    let archive_path = temp_dir.path().join("source.tar.gz");
    client.download_file(&url, &archive_path)?;

    let source_dir = temp_dir.path().join("source");
    fs_err::create_dir(&source_dir)?;
    let archive = fs_err::File::open(&archive_path)?;
    let decoder = flate2::read::GzDecoder::new(archive);
    let mut archive = tar::Archive::new(decoder);
    for entry in archive.entries()? {
        let mut entry = entry?;
        let path = entry.path()?;
        let stripped = path.components().skip(1).collect::<PathBuf>();
        if stripped.as_os_str().is_empty() {
            continue;
        }
        entry.unpack(source_dir.join(stripped))?;
    }

    Ok(process::trimmed_text(&process::argv([
        "nix",
        "hash",
        "path",
        "--sri",
        &source_dir.to_string_lossy(),
    ]))?)
}

fn current_version() -> Result<Option<String>, Box<dyn std::error::Error>> {
    let Some(path) = find_nvidia_driver_file()? else {
        return Ok(None);
    };
    let content = fs_err::read_to_string(path)?;
    Ok(extract_string_value(&content, "version"))
}

fn find_nvidia_driver_file() -> Result<Option<PathBuf>, Box<dyn std::error::Error>> {
    let mut cursor = std::env::current_dir()?;
    loop {
        let candidate = cursor.join(NVIDIA_DRIVER_FILE);
        if candidate.exists() {
            return Ok(Some(candidate));
        }
        if !cursor.pop() {
            return Ok(None);
        }
    }
}

fn extract_string_value(content: &str, name: &str) -> Option<String> {
    for line in content.lines() {
        let trimmed = line.trim();
        let Some(rest) = trimmed.strip_prefix(name) else {
            continue;
        };
        let Some(rest) = rest.trim_start().strip_prefix('=') else {
            continue;
        };
        let Some(rest) = rest.trim_start().strip_prefix('"') else {
            continue;
        };
        let Some(end) = rest.find('"') else {
            continue;
        };
        return Some(rest[..end].to_owned());
    }
    None
}

fn update_nix_file(
    driver_version: &str,
    hashes: &DriverHashes,
) -> Result<(), Box<dyn std::error::Error>> {
    let path = find_nvidia_driver_file()?.ok_or("modules/nixos/nvidia-driver.nix not found")?;
    eprintln!("info: Updating {}...", path.display());
    fs_err::write(&path, format_nix_file(driver_version, hashes))?;
    eprintln!("success: Successfully updated {}", path.display());
    Ok(())
}

fn format_nix_file(driver_version: &str, hashes: &DriverHashes) -> String {
    format!(
        "{{\n  version = \"{}\";\n  sha256_64bit = \"{}\";\n  sha256_aarch64 = \"{}\";\n  openSha256 = \"{}\";\n  settingsSha256 = \"{}\";\n  persistencedSha256 = \"{}\";\n}}\n",
        nix::escape_string(driver_version),
        nix::escape_string(&hashes.sha256),
        nix::escape_string(&hashes.sha256_aarch64),
        nix::escape_string(&hashes.open_sha256),
        nix::escape_string(&hashes.settings_sha256),
        nix::escape_string(&hashes.persistenced_sha256),
    )
}

fn log_hashes(hashes: &DriverHashes) {
    println!(
        "\nsuccess: Hash computation completed!\n\nsha256 = \"{}\";\nsha256_aarch64 = \"{}\";\nopenSha256 = \"{}\";\nsettingsSha256 = \"{}\";\npersistencedSha256 = \"{}\";",
        hashes.sha256,
        hashes.sha256_aarch64,
        hashes.open_sha256,
        hashes.settings_sha256,
        hashes.persistenced_sha256,
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse_versions<const N: usize>(versions: [&str; N]) -> Vec<NvidiaVersion> {
        let parsed = versions
            .into_iter()
            .filter_map(NvidiaVersion::parse)
            .collect::<Vec<_>>();
        assert_eq!(parsed.len(), N);
        parsed
    }

    #[test]
    fn sorts_nvidia_versions_with_leading_zero_components() {
        let mut versions = ["580.126.18", "595.71.05", "575.64.05"];
        versions.sort_by_key(|version| parse_nvidia_version(version));
        assert_eq!(versions, ["575.64.05", "580.126.18", "595.71.05"]);
    }

    #[test]
    fn parses_nvidia_versions_as_semver() {
        assert_eq!(
            parse_nvidia_version("595.71.05"),
            Version::parse("595.71.5").ok()
        );
        assert_eq!(
            parse_nvidia_version("600.1"),
            Version::parse("600.1.0").ok()
        );
        assert_eq!(parse_nvidia_version("600.1.2.3"), None);
        assert_eq!(parse_nvidia_version("600..1"), None);
    }

    #[test]
    fn parses_nvidia_directory_index_hrefs() {
        let html = "<a href='..'>..</a><a href='525.60.13/'>ok</a><a href=\"595.71.05/\">ok</a><a href='latest.txt'>bad</a>";
        assert_eq!(
            parse_versions_from_index(html)
                .iter()
                .map(NvidiaVersion::as_str)
                .collect::<Vec<_>>(),
            vec!["525.60.13", "595.71.05"]
        );
    }

    #[test]
    fn selects_latest_shared_version() {
        let left = parse_versions(["580.126.18", "595.71.05", "600.1"]);
        let right = parse_versions(["580.126.18", "595.71.05"]);
        assert_eq!(latest_shared(&left, &right), Some("595.71.05"));
    }

    #[test]
    fn ignores_invalid_versions_when_selecting_latest_shared() {
        let left = parse_versions(["580.126.18"]);
        let right = parse_versions(["580.126.18"]);

        assert_eq!(latest_shared(&left, &right), Some("580.126.18"));
    }

    #[test]
    fn extracts_and_formats_nix_hash_file() {
        let content = "{\n  version = \"595.71.05\";\n}\n";
        assert_eq!(
            extract_string_value(content, "version").as_deref(),
            Some("595.71.05")
        );
        let hashes = DriverHashes {
            sha256: "sha256-a".to_owned(),
            sha256_aarch64: "sha256-b".to_owned(),
            open_sha256: "sha256-c".to_owned(),
            settings_sha256: "sha256-d".to_owned(),
            persistenced_sha256: "sha256-e".to_owned(),
        };
        assert!(format_nix_file("1.2.3", &hashes).contains("version = \"1.2.3\";"));
    }
}
