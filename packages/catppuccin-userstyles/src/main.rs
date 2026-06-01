use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

use clap::Parser;
use serde::Serialize;
use serde_json::{Value, json};
use sha1::{Digest as _, Sha1};
use walkdir::WalkDir;

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

const EXCLUDED_STYLE_IDS: &[&str] = &["gmail", "shinigami-eyes"];
const DEFAULT_DARK_FLAVORS: &[&str] = &["frappe", "macchiato", "mocha"];
const DEFAULT_OUTPUT_DIR_NAME: &str = "userstyles-output";
const HEADER_START: &str = "/* ==UserStyle==";
const HEADER_END: &str = "==/UserStyle== */";

#[derive(Debug, Parser)]
#[command(
    name = "build-catppuccin-userstyles",
    about = "Build Catppuccin Stylus import variants"
)]
struct Cli {
    /// Opt excluded userstyles back in. May be repeated or comma-separated.
    #[arg(long, value_delimiter = ',')]
    include: Vec<String>,

    /// Path to the catppuccin/userstyles checkout.
    userstyles_dir: Option<PathBuf>,

    /// Directory for generated Stylus import JSON files.
    output_dir: Option<PathBuf>,
}

#[derive(Debug, Clone, Serialize)]
struct StylusSettings {
    settings: Settings,
}

#[derive(Debug, Clone, Serialize)]
struct Settings {
    #[serde(rename = "updateInterval")]
    update_interval: u8,
    #[serde(rename = "updateOnlyEnabled")]
    update_only_enabled: bool,
    #[serde(rename = "patchCsp")]
    patch_csp: bool,
    #[serde(rename = "editor.linter")]
    editor_linter: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(untagged)]
enum StylusEntry {
    Settings(StylusSettings),
    Userstyle(Box<StylusUserstyle>),
}

#[derive(Debug, Clone, Serialize)]
struct StylusUserstyle {
    enabled: bool,
    name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    author: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    url: Option<String>,
    #[serde(rename = "updateUrl", skip_serializing_if = "Option::is_none")]
    update_url: Option<String>,
    #[serde(rename = "usercssData")]
    usercss_data: UsercssMetadata,
    #[serde(rename = "sourceCode")]
    source_code: String,
    #[serde(rename = "originalDigest")]
    original_digest: String,
}

#[derive(Debug, Clone, Serialize)]
struct UsercssMetadata {
    name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    author: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    url: Option<String>,
    #[serde(rename = "updateURL", skip_serializing_if = "Option::is_none")]
    update_url: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty")]
    vars: BTreeMap<String, UsercssVar>,
}

#[derive(Debug, Clone, Serialize)]
struct UsercssVar {
    #[serde(rename = "type")]
    kind: String,
    label: String,
    value: Value,
    default: Value,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    options: Vec<UsercssOption>,
}

#[derive(Debug, Clone, Serialize)]
struct UsercssOption {
    name: String,
    label: String,
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    default: bool,
}

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    let userstyles_dir = resolve_userstyles_dir(cli.userstyles_dir)?;
    let output_dir = cli
        .output_dir
        .unwrap_or_else(|| std::env::temp_dir().join(DEFAULT_OUTPUT_DIR_NAME));
    let included = cli.include.into_iter().collect::<BTreeSet<_>>();
    let all_files = userstyle_files(&userstyles_dir)?;
    let source_files = all_files
        .into_iter()
        .filter(|file| {
            let id = style_id(file);
            !EXCLUDED_STYLE_IDS.contains(&id.as_str()) || included.contains(&id)
        })
        .collect::<Vec<_>>();
    if source_files.is_empty() {
        return Err(format!(
            "no userstyles found under {}",
            userstyles_dir.join("styles").display()
        )
        .into());
    }

    fs_err::create_dir_all(&output_dir)?;
    let base = build_stylus_import(&source_files)?;
    write_json(&output_dir.join("catppuccin-import.json"), &base)?;
    eprintln!(
        "info: base import includes {} styles",
        base.len().saturating_sub(1)
    );
    let variants = build_variants(&output_dir, &base)?;
    eprintln!(
        "success: generated {variants} variants in {}",
        output_dir.display()
    );
    Ok(())
}

fn resolve_userstyles_dir(arg: Option<PathBuf>) -> Result<PathBuf> {
    if let Some(path) = arg {
        return Ok(path);
    }
    if let Some(path) = std::env::var_os("USERSTYLES_DIR") {
        return Ok(PathBuf::from(path));
    }
    for candidate in ["userstyles", "catppuccin-userstyles"] {
        let path = std::env::temp_dir().join(candidate);
        if path.join("styles").is_dir() {
            return Ok(path);
        }
    }
    Ok(std::env::temp_dir().join("userstyles"))
}

fn userstyle_files(root: &Path) -> Result<Vec<PathBuf>> {
    let mut files = WalkDir::new(root.join("styles"))
        .follow_links(false)
        .into_iter()
        .filter_map(std::result::Result::ok)
        .filter(|entry| entry.file_type().is_file() && entry.file_name() == "catppuccin.user.less")
        .map(walkdir::DirEntry::into_path)
        .collect::<Vec<_>>();
    files.sort();
    Ok(files)
}

fn style_id(file: &Path) -> String {
    file.parent()
        .and_then(Path::file_name)
        .and_then(std::ffi::OsStr::to_str)
        .unwrap_or_default()
        .to_owned()
}

fn build_stylus_import(files: &[PathBuf]) -> Result<Vec<StylusEntry>> {
    let mut data = vec![StylusEntry::Settings(StylusSettings {
        settings: Settings {
            update_interval: 24,
            update_only_enabled: true,
            patch_csp: true,
            editor_linter: String::new(),
        },
    })];

    for file in files {
        let source_code = fs_err::read_to_string(file)?;
        let metadata = parse_usercss_metadata(&source_code)?;
        data.push(StylusEntry::Userstyle(Box::new(StylusUserstyle {
            enabled: true,
            name: metadata.name.clone(),
            description: metadata.description.clone(),
            author: metadata.author.clone(),
            url: metadata.url.clone(),
            update_url: metadata.update_url.clone(),
            original_digest: sha1_hex(&source_code),
            usercss_data: metadata,
            source_code,
        })));
    }
    Ok(data)
}

fn build_variants(output_dir: &Path, base: &[StylusEntry]) -> Result<usize> {
    let first_style = base
        .iter()
        .find_map(|entry| match entry {
            StylusEntry::Userstyle(style) => Some(style),
            StylusEntry::Settings(_) => None,
        })
        .ok_or("no usercss styles were generated")?;
    let accents = select_options(&first_style.usercss_data, "accentColor")?
        .iter()
        .map(|option| option.name.clone())
        .collect::<Vec<_>>();
    let mut count = 0usize;
    for dark_flavor in DEFAULT_DARK_FLAVORS {
        for accent in &accents {
            let mut variant = base.to_vec();
            for entry in &mut variant {
                if let StylusEntry::Userstyle(style) = entry {
                    set_select_default(&mut style.usercss_data, "lightFlavor", "latte")?;
                    set_select_default(&mut style.usercss_data, "darkFlavor", dark_flavor)?;
                    set_select_default(&mut style.usercss_data, "accentColor", accent)?;
                    let header = stringify_usercss_metadata(&style.usercss_data);
                    style.source_code = replace_header(&style.source_code, &header)?;
                    style.original_digest = sha1_hex(&style.source_code);
                }
            }
            let name = format!("catppuccin-latte-{dark_flavor}-{accent}-import.json");
            write_json(&output_dir.join(name), &variant)?;
            count += 1;
        }
    }
    Ok(count)
}

fn parse_usercss_metadata(source: &str) -> Result<UsercssMetadata> {
    let header = header_block(source)?;
    let mut metadata = UsercssMetadata {
        name: String::new(),
        description: None,
        author: None,
        url: None,
        update_url: None,
        vars: BTreeMap::new(),
    };
    for line in header.lines() {
        let line = line.trim().trim_start_matches('*').trim();
        let Some(rest) = line.strip_prefix('@') else {
            continue;
        };
        let mut parts = rest.splitn(2, char::is_whitespace);
        let key = parts.next().unwrap_or_default();
        let value = parts.next().unwrap_or_default().trim();
        match key {
            "name" => metadata.name = value.to_owned(),
            "description" => metadata.description = optional_text(value),
            "author" => metadata.author = optional_text(value),
            "url" => metadata.url = optional_text(value),
            "updateURL" => metadata.update_url = optional_text(value),
            "var" => {
                if let Some((name, var)) = parse_var(value) {
                    metadata.vars.insert(name, var);
                }
            }
            _ => {}
        }
    }
    if metadata.name.is_empty() {
        return Err("missing @name in UserCSS metadata".into());
    }
    Ok(metadata)
}

fn parse_var(value: &str) -> Option<(String, UsercssVar)> {
    let tokens = shell_words::split(value).ok()?;
    let kind = tokens.first()?.to_owned();
    let name = tokens.get(1)?.to_owned();
    let label = tokens.get(2).cloned().unwrap_or_else(|| name.clone());
    let raw_default = tokens.get(3).cloned().unwrap_or_default();
    let mut options = Vec::new();
    if kind == "select" {
        let option_values = parse_option_list(value).unwrap_or_else(|| {
            raw_default
                .split(',')
                .map(str::trim)
                .filter(|item| !item.is_empty())
                .map(ToOwned::to_owned)
                .collect()
        });
        options = option_values
            .iter()
            .map(|option| UsercssOption {
                name: option.clone(),
                label: option.clone(),
                default: option == &raw_default,
            })
            .collect();
    }
    Some((
        name,
        UsercssVar {
            kind,
            label,
            value: json!(raw_default),
            default: json!(raw_default),
            options,
        },
    ))
}

fn parse_option_list(value: &str) -> Option<Vec<String>> {
    let start = value.find('[')?;
    let end = value.rfind(']')?;
    let json_text = &value[start..=end];
    if let Ok(values) = serde_json::from_str::<Vec<String>>(json_text) {
        return Some(values);
    }
    let normalized = json_text.replace('\'', "\"");
    serde_json::from_str::<Vec<String>>(&normalized).ok()
}

fn optional_text(value: &str) -> Option<String> {
    if value.is_empty() {
        None
    } else {
        Some(value.to_owned())
    }
}

fn select_options<'a>(metadata: &'a UsercssMetadata, name: &str) -> Result<&'a [UsercssOption]> {
    metadata
        .vars
        .get(name)
        .map(|var| var.options.as_slice())
        .filter(|options| !options.is_empty())
        .ok_or_else(|| format!("missing select variable {name} in {}", metadata.name).into())
}

fn set_select_default(metadata: &mut UsercssMetadata, name: &str, value: &str) -> Result<()> {
    let var = metadata
        .vars
        .get_mut(name)
        .ok_or_else(|| format!("missing select variable {name} in {}", metadata.name))?;
    if !var.options.iter().any(|option| option.name == value) {
        return Err(format!("unknown {name} value {value} for {}", metadata.name).into());
    }
    var.default = json!(value);
    var.value = json!(value);
    for option in &mut var.options {
        option.default = option.name == value;
    }
    Ok(())
}

fn stringify_usercss_metadata(metadata: &UsercssMetadata) -> String {
    let mut lines = vec![HEADER_START.to_owned(), format!("@name {}", metadata.name)];
    if let Some(value) = &metadata.description {
        lines.push(format!("@description {value}"));
    }
    if let Some(value) = &metadata.author {
        lines.push(format!("@author {value}"));
    }
    if let Some(value) = &metadata.url {
        lines.push(format!("@url {value}"));
    }
    if let Some(value) = &metadata.update_url {
        lines.push(format!("@updateURL {value}"));
    }
    for (name, var) in &metadata.vars {
        if var.kind == "select" {
            let options = var
                .options
                .iter()
                .map(|option| option.name.as_str())
                .collect::<Vec<_>>();
            lines.push(format!(
                "@var select {name} \"{}\" {}",
                var.label,
                serde_json::to_string(&options).unwrap_or_else(|_| "[]".to_owned())
            ));
        }
    }
    lines.push(HEADER_END.to_owned());
    lines.join("\n")
}

fn header_block(source: &str) -> Result<&str> {
    let start = source
        .find(HEADER_START)
        .ok_or("missing UserStyle metadata header")?;
    let after_start = start + HEADER_START.len();
    let relative_end = source[after_start..]
        .find(HEADER_END)
        .ok_or("missing UserStyle metadata footer")?;
    Ok(&source[start..after_start + relative_end + HEADER_END.len()])
}

fn replace_header(source: &str, header: &str) -> Result<String> {
    let start = source
        .find(HEADER_START)
        .ok_or("missing UserStyle metadata header")?;
    let after_start = start + HEADER_START.len();
    let relative_end = source[after_start..]
        .find(HEADER_END)
        .ok_or("missing UserStyle metadata footer")?;
    let end = after_start + relative_end + HEADER_END.len();
    Ok(format!("{}{}{}", &source[..start], header, &source[end..]))
}

fn sha1_hex(source: &str) -> String {
    let digest = Sha1::digest(source.as_bytes());
    digest.iter().map(|byte| format!("{byte:02x}")).collect()
}

fn write_json(path: &Path, data: &[StylusEntry]) -> Result<()> {
    fs_err::write(path, serde_json::to_string_pretty(data)?)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_metadata_and_select_options() -> Result<()> {
        let source = r#"/* ==UserStyle==
@name Demo
@description Example
@var select accentColor "Accent" ["pink","blue"]
==/UserStyle== */
body {}"#;
        let metadata = parse_usercss_metadata(source)?;
        assert_eq!(metadata.name, "Demo");
        assert_eq!(select_options(&metadata, "accentColor")?.len(), 2);
        Ok(())
    }

    #[test]
    fn replaces_header() -> Result<()> {
        let source = "/* ==UserStyle==\n@name Demo\n==/UserStyle== */\nbody {}";
        let replaced = replace_header(source, "/* ==UserStyle==\n@name Next\n==/UserStyle== */")?;
        assert!(replaced.contains("@name Next"));
        assert!(replaced.ends_with("body {}"));
        Ok(())
    }
}
