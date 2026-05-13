use crate::constants::{COMMON_BRANCH_NAMES, DEFAULT_REMOTE};
use anyhow::{Context, Result};
use jj_lib::backend::CommitId;
use jj_lib::commit::Commit;
use jj_lib::ref_name::{RefName, RemoteName};
use jj_lib::repo::{ReadonlyRepo, Repo};

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ChangeState {
    None,
    RemoteOnly,
    LocalOnly,
    LocalAndRemote,
}

#[derive(Clone, Debug)]
pub struct RemoteBookmark {
    pub name: String,
    pub target: CommitId,
}

#[derive(Clone, Debug)]
pub struct ChangeSet {
    pub state: ChangeState,
    pub remote: RemoteBookmark,
    pub working_copy: Commit,
}

#[allow(clippy::future_not_send)]
pub async fn inspect(
    repo: &ReadonlyRepo,
    workspace_name: &jj_lib::ref_name::WorkspaceName,
    branch: &str,
) -> Result<ChangeSet> {
    let remote = remote_bookmark(repo, branch)?;
    let working_copy_id = repo
        .view()
        .get_wc_commit_id(workspace_name)
        .with_context(|| {
            format!(
                "jj workspace '{}' has no working-copy commit",
                workspace_name.as_str()
            )
        })?;
    let working_copy = repo
        .store()
        .get_commit_async(working_copy_id)
        .await
        .context("failed to load jj working-copy commit")?;
    let local_head_id = working_copy
        .parent_ids()
        .first()
        .cloned()
        .unwrap_or_else(|| working_copy.id().clone());
    let local_tip = repo
        .store()
        .get_commit_async(&local_head_id)
        .await
        .context("failed to load jj local head commit")?;

    let has_working_copy_changes =
        working_copy.has_conflict() || !working_copy.is_empty(repo).await?;
    let local_ahead = local_tip.id() != &remote.target
        && repo
            .index()
            .is_ancestor(&remote.target, local_tip.id())
            .context("failed to compare local head with remote bookmark")?;
    let remote_ahead = local_tip.id() != &remote.target
        && repo
            .index()
            .is_ancestor(local_tip.id(), &remote.target)
            .context("failed to compare remote bookmark with local head")?;
    let diverged = local_tip.id() != &remote.target && !local_ahead && !remote_ahead;

    let local = has_working_copy_changes || local_ahead || diverged;
    let remote_changed = remote_ahead || diverged;

    Ok(ChangeSet {
        state: classify(local, remote_changed),
        remote,
        working_copy,
    })
}

#[must_use]
pub const fn classify(local: bool, remote: bool) -> ChangeState {
    match (local, remote) {
        (false, false) => ChangeState::None,
        (false, true) => ChangeState::RemoteOnly,
        (true, false) => ChangeState::LocalOnly,
        (true, true) => ChangeState::LocalAndRemote,
    }
}

fn remote_bookmark(repo: &ReadonlyRepo, branch: &str) -> Result<RemoteBookmark> {
    let remote_name = RemoteName::new(DEFAULT_REMOTE);
    if branch != crate::repo::DETACHED_HEAD
        && let Some(remote) = find_remote_bookmark(repo, branch, remote_name)
    {
        return Ok(remote);
    }

    for branch in COMMON_BRANCH_NAMES {
        if let Some(remote) = find_remote_bookmark(repo, branch, remote_name) {
            return Ok(remote);
        }
    }

    repo.view()
        .remote_bookmarks(remote_name)
        .find_map(|(name, remote_ref)| {
            remote_ref.target.as_normal().map(|target| RemoteBookmark {
                name: format!("{}@{DEFAULT_REMOTE}", name.as_str()),
                target: target.clone(),
            })
        })
        .ok_or_else(|| {
            anyhow::anyhow!("no non-conflicting remote bookmark found for {DEFAULT_REMOTE}")
        })
}

fn find_remote_bookmark(
    repo: &ReadonlyRepo,
    branch: &str,
    remote_name: &RemoteName,
) -> Option<RemoteBookmark> {
    let name = RefName::new(branch);
    let remote_ref = repo
        .view()
        .get_remote_bookmark(name.to_remote_symbol(remote_name));
    remote_ref.target.as_normal().map(|target| RemoteBookmark {
        name: format!("{branch}@{DEFAULT_REMOTE}"),
        target: target.clone(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classify_change_states() {
        assert_eq!(classify(false, false), ChangeState::None);
        assert_eq!(classify(false, true), ChangeState::RemoteOnly);
        assert_eq!(classify(true, false), ChangeState::LocalOnly);
        assert_eq!(classify(true, true), ChangeState::LocalAndRemote);
    }
}
