use anyhow::{Context, Result};
use notify::{RecursiveMode, Watcher};
use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::sync::mpsc;
use std::sync::mpsc::RecvTimeoutError;
use std::time::{Duration, Instant};

pub fn wait_for_paths_to_disappear(paths: &[PathBuf], timeout: Duration) -> Result<bool> {
    if paths.iter().all(|path| !path.exists()) {
        return Ok(true);
    }

    let (tx, rx) = mpsc::channel();
    let mut watcher = notify::recommended_watcher(move |event| {
        // INTENTIONAL: the receiver can go away after the wait loop exits.
        let _ = tx.send(event);
    })
    .context("failed to start file watcher")?;

    for parent in parent_dirs(paths) {
        watcher
            .watch(&parent, RecursiveMode::NonRecursive)
            .with_context(|| format!("failed to watch {}", parent.display()))?;
    }

    let started = Instant::now();
    while started.elapsed() < timeout {
        if paths.iter().all(|path| !path.exists()) {
            return Ok(true);
        }

        let remaining = timeout.saturating_sub(started.elapsed());
        let wait = remaining.min(Duration::from_millis(500));
        match rx.recv_timeout(wait) {
            Ok(Ok(_event)) => {}
            Ok(Err(err)) => return Err(err).context("file watcher reported an error"),
            Err(RecvTimeoutError::Timeout) => {}
            Err(RecvTimeoutError::Disconnected) => {
                return Ok(paths.iter().all(|path| !path.exists()));
            }
        }
    }

    Ok(paths.iter().all(|path| !path.exists()))
}

fn parent_dirs(paths: &[PathBuf]) -> Vec<PathBuf> {
    let mut parents = paths
        .iter()
        .filter_map(|path| Path::new(path).parent())
        .map(Path::to_path_buf)
        .collect::<HashSet<_>>()
        .into_iter()
        .collect::<Vec<_>>();
    parents.sort();
    parents
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wait_for_paths_to_disappear_returns_immediately_when_absent() -> Result<()> {
        let dir = tempfile::tempdir()?;
        let missing = dir.path().join("missing.lock");

        assert!(wait_for_paths_to_disappear(
            &[missing],
            Duration::from_secs(5)
        )?);
        Ok(())
    }

    #[test]
    fn parent_dirs_deduplicates_matching_parents() {
        let paths = vec![
            PathBuf::from("/tmp/repo/.git/index.lock"),
            PathBuf::from("/tmp/repo/.git/HEAD.lock"),
        ];

        assert_eq!(parent_dirs(&paths), vec![PathBuf::from("/tmp/repo/.git")]);
    }
}
