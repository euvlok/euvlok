use std::ffi::OsStr;
use std::path::{Path, PathBuf};

use clap::{Parser, Subcommand};
use dotfiles_common::process::{self, argv};
use serde::Deserialize;
use walkdir::WalkDir;

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

#[derive(Debug, Parser)]
#[command(
    name = "github-maintenance",
    about = "Repository maintenance commands for GitHub Actions"
)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    CheckWorkflows,
    LintWorkflows,
    UpdateBrowserExtensions,
    UpdateCustomPackages,
    UpdateTrivialFlakeInputs,
}

#[derive(Debug, Deserialize)]
struct FlakeLock {
    nodes: serde_json::Map<String, serde_json::Value>,
}

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    match Cli::parse().command {
        Commands::CheckWorkflows => check_workflows(),
        Commands::LintWorkflows => lint_workflows(),
        Commands::UpdateBrowserExtensions => update_browser_extensions(),
        Commands::UpdateCustomPackages => update_custom_packages(),
        Commands::UpdateTrivialFlakeInputs => update_trivial_flake_inputs(),
    }
}

fn check_workflows() -> Result<()> {
    let files = workflow_files();
    if files.is_empty() {
        eprintln!("warning: no workflow files found");
        return Ok(());
    }
    let actionlint = find_command("actionlint").or_else(|| {
        PathBuf::from("node_modules/.bin/node-actionlint")
            .exists()
            .then(|| PathBuf::from("node_modules/.bin/node-actionlint"))
    });
    if let Some(actionlint) = actionlint {
        for file in &files {
            run_command([
                actionlint.to_string_lossy().into_owned(),
                file.to_string_lossy().into_owned(),
            ])?;
        }
    } else {
        eprintln!("warning: actionlint unavailable; checked only that workflow files exist");
    }
    for file in files {
        eprintln!("info: workflow present: {}", file.display());
    }
    Ok(())
}

fn lint_workflows() -> Result<()> {
    check_workflows()?;
    if let Some(zizmor) = find_command("zizmor") {
        run_command([
            zizmor.to_string_lossy().into_owned(),
            "--offline".into(),
            "--no-progress".into(),
            "--format=github".into(),
            ".github/workflows".into(),
        ])?;
    } else if let Some(uvx) = find_command("uvx") {
        run_command([
            uvx.to_string_lossy().into_owned(),
            "zizmor".into(),
            "--offline".into(),
            "--no-progress".into(),
            "--format=github".into(),
            ".github/workflows".into(),
        ])?;
    } else if let Some(pipx) = find_command("pipx") {
        run_command([
            pipx.to_string_lossy().into_owned(),
            "run".into(),
            "zizmor".into(),
            "--offline".into(),
            "--no-progress".into(),
            "--format=github".into(),
            ".github/workflows".into(),
        ])?;
    } else {
        eprintln!("warning: skipping zizmor because zizmor, uvx, and pipx are unavailable");
    }
    Ok(())
}

fn update_browser_extensions() -> Result<()> {
    let browser = std::env::var("BROWSER").unwrap_or_else(|_| "all".to_owned());
    let mut source_files = find_files(["modules", "hosts"], |path| {
        path.file_name() == Some(OsStr::new("sources.nix"))
    });
    source_files.retain(|file| {
        browser == "all"
            || file
                .parent()
                .and_then(Path::file_name)
                .and_then(OsStr::to_str)
                .is_some_and(|name| name == browser)
    });
    if source_files.is_empty() {
        eprintln!("info: no extension source files found for {browser}");
        return Ok(());
    }
    for source in source_files {
        eprintln!("info: updating {}", source.display());
        if find_command("browser-extension-update").is_some() {
            run_command([
                "browser-extension-update".into(),
                source.to_string_lossy().into_owned(),
            ])?;
        } else {
            run_command([
                "cargo".into(),
                "run".into(),
                "--package".into(),
                "browser-extension-update".into(),
                "--".into(),
                source.to_string_lossy().into_owned(),
            ])?;
        }
    }
    if !has_unstaged_diff(&[])? {
        eprintln!("info: no extension changes detected");
        return Ok(());
    }
    let title = if browser == "all" {
        "chore(browsers): update extensions".to_owned()
    } else {
        format!("chore({browser}): update extensions")
    };
    commit_and_push(
        &title,
        "Updated extension definitions.",
        &["hosts", "modules"],
    )
}

fn update_custom_packages() -> Result<()> {
    let package_root = Path::new("pkgs");
    if !package_root.is_dir() {
        eprintln!("info: pkgs/ not found, skipping custom package updates");
        return Ok(());
    }
    let nix_files = find_files(["pkgs"], |path| path.extension() == Some(OsStr::new("nix")));
    if nix_files.is_empty() {
        eprintln!("info: no package derivations found under pkgs/");
        return Ok(());
    }
    for file in nix_files {
        eprintln!("info: update hook for {}", file.display());
        let _ = run_command([
            "bash".into(),
            "./pkgs/update.sh".into(),
            file.to_string_lossy().into_owned(),
        ]);
    }
    if !has_unstaged_diff(&["pkgs"])? {
        eprintln!("info: no package changes detected");
        return Ok(());
    }
    commit_and_push(
        "chore(pkgs): update custom packages",
        "Updated package definitions.",
        &["pkgs"],
    )
}

fn update_trivial_flake_inputs() -> Result<()> {
    let lock_path = Path::new("flake.lock");
    if !lock_path.exists() {
        eprintln!("warning: flake.lock not found, skipping");
        return Ok(());
    }
    let lock = serde_json::from_str::<FlakeLock>(&fs_err::read_to_string(lock_path)?)?;
    let Some(root_inputs) = lock
        .nodes
        .get("root")
        .and_then(|root| root.get("inputs"))
        .and_then(serde_json::Value::as_object)
    else {
        eprintln!("info: no root inputs found");
        return Ok(());
    };
    let inputs = root_inputs
        .keys()
        .filter(|name| name.ends_with("-trivial"))
        .cloned()
        .collect::<Vec<_>>();
    if inputs.is_empty() {
        eprintln!("info: no trivial inputs found to update");
        return Ok(());
    }
    eprintln!("info: updating trivial inputs: {}", inputs.join(" "));
    let mut command = argv(["nix", "flake", "update"]);
    command.extend(inputs);
    process::run_with_env(
        &command,
        [(
            "NIX_CONFIG",
            "extra-experimental-features = nix-command flakes pipe-operator",
        )],
    )?;
    if !has_unstaged_diff(&["flake.lock"])? {
        eprintln!("info: no changes detected in flake.lock");
        return Ok(());
    }
    commit_and_push(
        "chore: update trivial flake inputs",
        "Updated trivial flake inputs.",
        &["flake.lock"],
    )
}

fn workflow_files() -> Vec<PathBuf> {
    find_files([".github/workflows"], |path| {
        path.extension()
            .and_then(OsStr::to_str)
            .is_some_and(|ext| ext == "yml" || ext == "yaml")
    })
}

fn find_files<const N: usize>(roots: [&str; N], predicate: impl Fn(&Path) -> bool) -> Vec<PathBuf> {
    let mut files = roots
        .iter()
        .filter(|root| Path::new(root).is_dir())
        .flat_map(|root| WalkDir::new(root).follow_links(false).into_iter())
        .filter_map(std::result::Result::ok)
        .filter(|entry| entry.file_type().is_file())
        .map(walkdir::DirEntry::into_path)
        .filter(|path| predicate(path))
        .collect::<Vec<_>>();
    files.sort();
    files
}

fn commit_and_push(title: &str, body: &str, add: &[&str]) -> Result<()> {
    run_command(["git", "config", "user.name", "github-actions[bot]"])?;
    run_command([
        "git",
        "config",
        "user.email",
        "41898282+github-actions[bot]@users.noreply.github.com",
    ])?;
    if let Ok(token) = std::env::var("GITHUB_TOKEN")
        && !token.trim().is_empty()
        && let Ok(repo) = std::env::var("GITHUB_REPOSITORY")
    {
        run_command([
            "git",
            "remote",
            "set-url",
            "origin",
            &format!("https://x-access-token:{token}@github.com/{repo}.git"),
        ])?;
    }
    let mut git_add = argv(["git", "add"]);
    git_add.extend(add.iter().map(|item| (*item).to_owned()));
    process::run(&git_add)?;
    if !has_staged_changes()? {
        eprintln!("info: no staged changes remain after git add");
        return Ok(());
    }
    run_command(["git", "commit", "-m", title, "-m", body])?;
    let ref_name = current_ref_name();
    run_command(["git", "push", "origin", &format!("HEAD:{ref_name}")])
}

fn current_ref_name() -> String {
    std::env::var("GITHUB_REF_NAME")
        .ok()
        .filter(|value| !value.trim().is_empty())
        .or_else(|| std::env::var("GITHUB_HEAD_REF").ok())
        .unwrap_or_else(|| "master".to_owned())
}

fn has_unstaged_diff(pathspecs: &[&str]) -> Result<bool> {
    let mut command = argv(["git", "diff", "--quiet"]);
    command.extend(pathspecs.iter().map(|item| (*item).to_owned()));
    Ok(!process::capture_with_env(&command, std::iter::empty::<(String, String)>())?.succeeded())
}

fn has_staged_changes() -> Result<bool> {
    Ok(!process::capture_with_env(
        &argv(["git", "diff", "--staged", "--quiet"]),
        std::iter::empty::<(String, String)>(),
    )?
    .succeeded())
}

fn find_command(command: &str) -> Option<PathBuf> {
    process::path_of(command)
}

fn run_command(args: impl IntoIterator<Item = impl AsRef<str>>) -> Result<()> {
    Ok(process::run(&argv(args))?)
}
