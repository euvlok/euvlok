use std::path::PathBuf;

use base64::Engine as _;
use clap::{ArgAction, Parser};
use dotfiles_common::http::Client;
use dotfiles_common::{fs, process};
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
) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    eprintln!("info: Checking {name} platform...");
    let body = client.text(&format!("{base_url}/"))?;
    let versions = parse_versions_from_index(&body);
    if versions.is_empty() {
        return Err(format!("no NVIDIA versions found for {name}").into());
    }
    Ok(versions)
}

fn parse_versions_from_index(html: &str) -> Vec<String> {
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
        if is_valid_version(candidate) {
            versions.push(candidate.to_owned());
        }
        rest = &value[end + 1..];
    }
    versions.sort_by(|a, b| compare_versions(a, b).cmp(&0));
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

fn compare_versions(left: &str, right: &str) -> i8 {
    let mut left_parts = left.split('.');
    let mut right_parts = right.split('.');
    loop {
        match (left_parts.next(), right_parts.next()) {
            (None, None) => return 0,
            (left, right) => {
                let left = left.and_then(|part| part.parse::<u64>().ok()).unwrap_or(0);
                let right = right.and_then(|part| part.parse::<u64>().ok()).unwrap_or(0);
                if left < right {
                    return -1;
                }
                if left > right {
                    return 1;
                }
            }
        }
    }
}

fn latest_shared<'a>(left: &'a [String], right: &[String]) -> Option<&'a str> {
    left.iter()
        .filter(|version| right.iter().any(|candidate| candidate == *version))
        .max_by(|a, b| compare_versions(a, b).cmp(&0))
        .map(String::as_str)
}

fn exit_if_current(update: bool, driver_version: &str) -> Result<(), Box<dyn std::error::Error>> {
    if !update {
        return Ok(());
    }
    let Some(current) = current_version()? else {
        return Ok(());
    };
    if compare_versions(driver_version, &current) < 0 {
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
    let bytes = client.bytes(&url)?;
    Ok(sri_from_sha256(Sha256::digest(&bytes).as_slice()))
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

fn sri_from_sha256(digest: &[u8]) -> String {
    format!(
        "sha256-{}",
        base64::engine::general_purpose::STANDARD.encode(digest)
    )
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
        escape_nix_string(driver_version),
        escape_nix_string(&hashes.sha256),
        escape_nix_string(&hashes.sha256_aarch64),
        escape_nix_string(&hashes.open_sha256),
        escape_nix_string(&hashes.settings_sha256),
        escape_nix_string(&hashes.persistenced_sha256),
    )
}

fn escape_nix_string(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
        .replace('\r', "\\r")
        .replace('\t', "\\t")
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

    #[test]
    fn sorts_nvidia_versions_with_leading_zero_components() {
        let mut versions = ["580.126.18", "595.71.05", "575.64.05"];
        versions.sort_by(|a, b| compare_versions(a, b).cmp(&0));
        assert_eq!(versions, ["575.64.05", "580.126.18", "595.71.05"]);
    }

    #[test]
    fn parses_nvidia_directory_index_hrefs() {
        let html = "<a href='..'>..</a><a href='525.60.13/'>ok</a><a href=\"595.71.05/\">ok</a><a href='latest.txt'>bad</a>";
        assert_eq!(
            parse_versions_from_index(html),
            vec!["525.60.13".to_owned(), "595.71.05".to_owned()]
        );
    }

    #[test]
    fn selects_latest_shared_version() {
        let left = vec![
            "580.126.18".to_owned(),
            "595.71.05".to_owned(),
            "600.1".to_owned(),
        ];
        let right = vec!["580.126.18".to_owned(), "595.71.05".to_owned()];
        assert_eq!(latest_shared(&left, &right), Some("595.71.05"));
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
