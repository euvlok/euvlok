use crate::file_state;
use anyhow::{Context, Result, bail};
use std::path::{Path, PathBuf};
use std::time::Duration;

pub const DETACHED_HEAD: &str = "HEAD";

pub fn require_repo_root() -> Result<PathBuf> {
    let repo = gix::discover(".").context("could not find repository root")?;
    let root = repo
        .workdir()
        .context("auto-rebase requires a non-bare git working tree")?;

    let root = root
        .canonicalize()
        .context("failed to canonicalize repository root")?;

    if !root.join(".euvlok").exists() {
        bail!("this is not an euvlok repository (missing .euvlok file)");
    }

    Ok(root)
}

pub fn original_branch(root: &Path) -> Result<String> {
    let repo = gix::open(root)
        .with_context(|| format!("failed to open git repository at {}", root.display()))?;
    let branch = repo.head_name()?.map_or_else(
        || DETACHED_HEAD.to_string(),
        |name| name.shorten().to_string(),
    );

    Ok(branch)
}

pub fn assert_no_git_locks(root: &Path) -> Result<()> {
    assert_no_git_locks_with_timeout(root, Duration::from_secs(5))
}

fn assert_no_git_locks_with_timeout(root: &Path, timeout: Duration) -> Result<()> {
    let locks = [root.join(".git/index.lock"), root.join(".git/HEAD.lock")];
    if locks.iter().all(|lock| !lock.exists()) {
        return Ok(());
    }

    eprintln!(
        "Git lock file detected. Waiting up to {}ms...",
        timeout.as_millis()
    );
    if file_state::wait_for_paths_to_disappear(&locks, timeout)? {
        return Ok(());
    }

    bail!("git locks still present after waiting");
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::thread;

    #[test]
    fn assert_no_git_locks_passes_when_locks_are_absent() -> Result<()> {
        let dir = tempfile::tempdir()?;
        fs::create_dir(dir.path().join(".git"))?;

        assert_no_git_locks(dir.path())
    }

    #[test]
    fn assert_no_git_locks_recovers_when_lock_disappears() -> Result<()> {
        let dir = tempfile::tempdir()?;
        fs::create_dir(dir.path().join(".git"))?;
        let lock = dir.path().join(".git/index.lock");
        fs::write(&lock, "")?;

        let lock_to_remove = lock.clone();
        let remover = thread::spawn(move || {
            thread::sleep(Duration::from_millis(100));
            fs::remove_file(lock_to_remove)
        });

        assert_no_git_locks_with_timeout(dir.path(), Duration::from_secs(2))?;
        let remove_result = remover
            .join()
            .map_err(|_| anyhow::anyhow!("lock remover thread panicked"))?;
        remove_result.context("failed to remove lock file")?;
        assert!(!lock.exists());
        Ok(())
    }

    #[test]
    fn assert_no_git_locks_errors_when_lock_persists() -> Result<()> {
        let dir = tempfile::tempdir()?;
        fs::create_dir(dir.path().join(".git"))?;
        fs::write(dir.path().join(".git/index.lock"), "")?;

        let err = match assert_no_git_locks_with_timeout(dir.path(), Duration::from_millis(50)) {
            Ok(()) => bail!("persistent lock should fail"),
            Err(err) => err,
        };

        assert!(err.to_string().contains("git locks still present"));
        Ok(())
    }
}
