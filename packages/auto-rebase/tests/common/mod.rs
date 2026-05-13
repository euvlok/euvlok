#![allow(dead_code)]

use anyhow::{Context, Result, bail};
use std::path::{Path, PathBuf};
use std::process::Command;

pub fn run(cwd: &Path, program: &str, args: &[&str]) -> Result<String> {
    let output = Command::new(program)
        .args(args)
        .current_dir(cwd)
        .output()
        .with_context(|| format!("failed to run {program} {}", args.join(" ")))?;
    if !output.status.success() {
        bail!(
            "{} {} failed\nstdout:\n{}\nstderr:\n{}",
            program,
            args.join(" "),
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
    }

    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

fn run_err(cwd: &Path, program: &str, args: &[&str]) -> Result<String> {
    let output = Command::new(program)
        .args(args)
        .current_dir(cwd)
        .output()
        .with_context(|| format!("failed to run {program} {}", args.join(" ")))?;
    if output.status.success() {
        bail!(
            "{} {} unexpectedly succeeded\nstdout:\n{}\nstderr:\n{}",
            program,
            args.join(" "),
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
    }

    Ok(format!(
        "{}{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    ))
}

pub fn git(cwd: &Path, args: &[&str]) -> Result<String> {
    run(cwd, "git", args)
}

fn configure_test_identity(repo: &Path) -> Result<()> {
    git(repo, &["config", "user.name", "Smoke Test"])?;
    git(repo, &["config", "user.email", "smoke@example.test"])?;
    Ok(())
}

pub fn write(path: impl AsRef<Path>, content: &str) -> Result<()> {
    std::fs::write(path.as_ref(), content)
        .with_context(|| format!("failed to write {}", path.as_ref().display()))
}

#[derive(Debug)]
pub struct Fixture {
    temp_dir: tempfile::TempDir,
    pub work: PathBuf,
    pub upstream: PathBuf,
}

impl Fixture {
    pub fn new() -> Result<Self> {
        let dir = tempfile::tempdir()?;
        let source = dir.path().join("source");
        let remote = dir.path().join("remote.git");
        let work = dir.path().join("work");
        let upstream = dir.path().join("upstream");

        git(
            dir.path(),
            &["init", "--initial-branch", "master", "source"],
        )?;
        write(source.join(".euvlok"), "1\n")?;
        write(source.join(".gitignore"), ".jj/\n")?;
        write(source.join("README.md"), "base\n")?;
        write(source.join("DELETE_ME.txt"), "delete me\n")?;
        write(source.join("STAGED.txt"), "base staged\n")?;
        write(source.join("UNSTAGED.txt"), "base unstaged\n")?;
        git(&source, &["add", "."])?;
        git(
            &source,
            &[
                "-c",
                "user.name=Smoke Test",
                "-c",
                "user.email=smoke@example.test",
                "commit",
                "-m",
                "base",
            ],
        )?;
        git(
            dir.path(),
            &[
                "clone",
                "--bare",
                source.to_str().context("non-utf8 source path")?,
                remote.to_str().context("non-utf8 remote path")?,
            ],
        )?;
        git(
            dir.path(),
            &[
                "clone",
                remote.to_str().context("non-utf8 remote path")?,
                work.to_str().context("non-utf8 work path")?,
            ],
        )?;
        git(
            dir.path(),
            &[
                "clone",
                remote.to_str().context("non-utf8 remote path")?,
                upstream.to_str().context("non-utf8 upstream path")?,
            ],
        )?;
        configure_test_identity(&source)?;
        configure_test_identity(&work)?;
        configure_test_identity(&upstream)?;

        Ok(Self {
            temp_dir: dir,
            work,
            upstream,
        })
    }

    pub fn commit_file(repo: &Path, file: &str, content: &str, message: &str) -> Result<()> {
        write(repo.join(file), content)?;
        git(repo, &["add", file])?;
        git(
            repo,
            &[
                "-c",
                "user.name=Smoke Test",
                "-c",
                "user.email=smoke@example.test",
                "commit",
                "-m",
                message,
            ],
        )?;
        Ok(())
    }

    pub fn commit_all(repo: &Path, message: &str) -> Result<()> {
        git(repo, &["add", "-A"])?;
        git(
            repo,
            &[
                "-c",
                "user.name=Smoke Test",
                "-c",
                "user.email=smoke@example.test",
                "commit",
                "-m",
                message,
            ],
        )?;
        Ok(())
    }

    pub fn push_upstream(&self) -> Result<()> {
        git(&self.upstream, &["push", "origin", "master"])?;
        Ok(())
    }

    pub fn push_upstream_branch(&self, branch: &str) -> Result<()> {
        git(&self.upstream, &["push", "origin", branch])?;
        Ok(())
    }

    pub fn run_auto_rebase(&self) -> Result<String> {
        run(&self.work, env!("CARGO_BIN_EXE_auto-rebase"), &[])
    }

    pub fn run_auto_rebase_args(&self, args: &[&str]) -> Result<String> {
        run(&self.work, env!("CARGO_BIN_EXE_auto-rebase"), args)
    }

    pub fn run_auto_rebase_err(&self) -> Result<String> {
        run_err(&self.work, env!("CARGO_BIN_EXE_auto-rebase"), &[])
    }

    pub fn run_auto_rebase_err_args(&self, args: &[&str]) -> Result<String> {
        run_err(&self.work, env!("CARGO_BIN_EXE_auto-rebase"), args)
    }

    pub fn run_auto_rebase_on_branch(&self, branch: &str) -> Result<String> {
        run(
            &self.work,
            env!("CARGO_BIN_EXE_auto-rebase"),
            &["--branch", branch],
        )
    }

    pub fn status(&self) -> Result<String> {
        git(&self.work, &["status", "--porcelain"])
    }

    pub fn current_checkout_name(&self) -> Result<String> {
        Ok(git(&self.work, &["rev-parse", "--abbrev-ref", "HEAD"])?
            .trim()
            .to_owned())
    }

    pub fn rev_parse(&self, rev: &str) -> Result<String> {
        Ok(git(&self.work, &["rev-parse", rev])?.trim().to_owned())
    }

    pub fn read(&self, file: &str) -> Result<String> {
        std::fs::read_to_string(self.work.join(file))
            .with_context(|| format!("failed to read {file}"))
    }

    #[must_use]
    pub fn backup_dir(&self) -> PathBuf {
        self.temp_dir.path().join("backups")
    }
}

pub fn backup_ref_from_output(output: &str) -> Result<&str> {
    output
        .lines()
        .find_map(|line| line.strip_prefix("Backup ref: "))
        .context("missing backup ref in output")
}
