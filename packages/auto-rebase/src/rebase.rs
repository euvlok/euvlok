use crate::changes::ChangeSet;
use crate::git_sync;
use anyhow::{Context, Result, bail};
use futures::TryStreamExt;
use jj_lib::backend::CommitId;
use jj_lib::commit::Commit;
use jj_lib::repo::{ReadonlyRepo, Repo};
use jj_lib::revset::RevsetExpression;
use jj_lib::rewrite::{
    MoveCommitsLocation, MoveCommitsStats, MoveCommitsTarget, RebaseOptions, RebasedCommit,
    move_commits,
};
use jj_lib::workspace::Workspace;
use std::sync::Arc;

#[derive(Debug)]
pub struct RebaseOutcome {
    pub target: String,
    pub committed: bool,
    pub stats: MoveCommitsStats,
    pub exported_bookmarks: usize,
    pub exported_tags: usize,
}

#[allow(clippy::future_not_send)]
pub async fn check_safety(
    repo: &Arc<ReadonlyRepo>,
    changes: &ChangeSet,
) -> Result<MoveCommitsStats> {
    let loc = plan_branch_rebase(repo, changes)?;
    let mut tx = repo.start_transaction();
    let stats = move_commits(tx.repo_mut(), &loc, &RebaseOptions::default())
        .await
        .context("failed to perform jj safety rebase")?;
    ensure_rebase_is_conflict_free(&stats)?;
    Ok(stats)
}

#[allow(clippy::future_not_send)]
pub async fn perform(
    workspace: &mut Workspace,
    repo: &Arc<ReadonlyRepo>,
    changes: &ChangeSet,
    dry_run: bool,
    auto_rebase: bool,
) -> Result<RebaseOutcome> {
    let loc = plan_branch_rebase(repo, changes)?;
    let mut tx = repo.start_transaction();
    let old_working_copy = changes.working_copy.clone();
    let stats = move_commits(tx.repo_mut(), &loc, &RebaseOptions::default())
        .await
        .context("failed to rebase jj commits")?;
    ensure_rebase_is_conflict_free(&stats)?;
    tx.repo_mut()
        .rebase_descendants()
        .await
        .context("failed to rebase descendants after moving jj commits")?;

    if dry_run || !auto_rebase {
        return Ok(RebaseOutcome {
            target: changes.remote.name.clone(),
            committed: false,
            stats,
            exported_bookmarks: 0,
            exported_tags: 0,
        });
    }

    let export_stats = git_sync::export_refs(tx.repo_mut())?;
    let new_repo = tx
        .commit(format!("auto-rebase onto {}", changes.remote.name))
        .await
        .context("failed to commit jj rebase operation")?;
    let new_working_copy = current_working_copy(&new_repo, workspace)
        .await
        .context("failed to load rebased working-copy commit")?;
    workspace
        .check_out(
            new_repo.op_id().clone(),
            Some(&old_working_copy.tree()),
            &new_working_copy,
        )
        .await
        .context("failed to check out rebased working copy")?;

    Ok(RebaseOutcome {
        target: changes.remote.name.clone(),
        committed: true,
        stats,
        exported_bookmarks: export_stats.failed_bookmarks.len(),
        exported_tags: export_stats.failed_tags.len(),
    })
}

fn plan_branch_rebase(repo: &ReadonlyRepo, changes: &ChangeSet) -> Result<MoveCommitsLocation> {
    let root_commit_ids = branch_roots(repo, changes.working_copy.id(), &changes.remote.target)
        .context("failed to compute jj branch roots for rebase")?;
    if root_commit_ids.is_empty() {
        bail!("no jj commits need rebasing onto {}", changes.remote.name);
    }

    Ok(MoveCommitsLocation {
        new_parent_ids: vec![changes.remote.target.clone()],
        new_child_ids: vec![],
        target: MoveCommitsTarget::Roots(root_commit_ids),
    })
}

fn branch_roots(
    repo: &ReadonlyRepo,
    branch: &CommitId,
    destination: &CommitId,
) -> Result<Vec<CommitId>> {
    pollster::block_on(async {
        RevsetExpression::commits(vec![destination.clone()])
            .range(&RevsetExpression::commits(vec![branch.clone()]))
            .roots()
            .evaluate(repo)
            .map_err(jj_lib::revset::RevsetEvaluationError::into_backend_error)?
            .stream()
            .try_collect()
            .await
            .map_err(|err| err.into_backend_error().into())
    })
}

#[allow(clippy::future_not_send)]
async fn current_working_copy(repo: &ReadonlyRepo, workspace: &Workspace) -> Result<Commit> {
    let wc_id = repo
        .view()
        .get_wc_commit_id(workspace.workspace_name())
        .with_context(|| {
            format!(
                "jj workspace '{}' has no working-copy commit",
                workspace.workspace_name().as_str()
            )
        })?;
    repo.store()
        .get_commit_async(wc_id)
        .await
        .context("failed to load current jj working-copy commit")
}

fn ensure_rebase_is_conflict_free(stats: &MoveCommitsStats) -> Result<()> {
    let conflicted = stats.rebased_commits.values().any(|rebased| match rebased {
        RebasedCommit::Rewritten(commit) => commit.has_conflict(),
        RebasedCommit::Abandoned { .. } => false,
    });

    if conflicted {
        bail!("rebase would introduce conflicts");
    }

    Ok(())
}
