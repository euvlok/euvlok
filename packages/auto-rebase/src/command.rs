use crate::backup;
use crate::changes::{self, ChangeState};
use crate::cli::Args;
use crate::context::RebaseContext;
use crate::git_sync;
use crate::jj;
use crate::rebase;
use crate::repo;
use anyhow::Result;

/// Runs the auto-rebase workflow with parsed command line arguments.
///
/// # Errors
///
/// Returns an error when repository discovery, Git synchronization, jj import/export, backup,
/// or rebase operations fail.
pub fn run(args: Args) -> Result<()> {
    let root = repo::require_repo_root()?;
    repo::assert_no_git_locks(&root)?;
    let original_branch = match args.branch {
        Some(branch) => branch,
        None => repo::original_branch(&root)?,
    };

    let ctx = RebaseContext::new(
        root,
        original_branch,
        args.dry_run,
        !args.no_auto_rebase,
        args.backup_dir,
    );
    let state = WorkflowState::capture(&ctx)?;
    state.print(&ctx);

    let backup = backup::create(&ctx)?;
    if let Some(ref_name) = &backup.ref_name {
        println!("Backup ref: {ref_name}");
        if let Some(manifest) = &backup.manifest {
            println!("Backup manifest: {}", manifest.display());
        }
    } else {
        println!("Backup skipped: repository has no HEAD commit");
    }

    let mut jj_workspace = jj::load_or_init(&ctx.repo_root, &ctx.original_branch)?;
    fetch_and_import(&ctx, &state, &mut jj_workspace)?;

    let changes = pollster::block_on(changes::inspect(
        &jj_workspace.repo,
        jj_workspace.workspace.workspace_name(),
        &ctx.original_branch,
    ))?;

    println!("Remote bookmark: {}", changes.remote.name);
    println!("Change state: {:?}", changes.state);
    handle_changes(&ctx, &state, &mut jj_workspace, &changes)?;

    state.staged_index_changes.restore(&ctx.repo_root)?;
    state.dirty_file_contents.restore(&ctx.repo_root)?;
    backup.cleanup(&ctx.repo_root)?;

    Ok(())
}

struct WorkflowState {
    jj_state: jj::JjWorkspaceState,
    deleted_tracked_paths: git_sync::DeletedTrackedPaths,
    staged_index_changes: git_sync::StagedIndexChanges,
    dirty_file_contents: git_sync::DirtyFileContents,
}

impl WorkflowState {
    fn capture(ctx: &RebaseContext) -> Result<Self> {
        Ok(Self {
            jj_state: jj::inspect(&ctx.repo_root)?,
            deleted_tracked_paths: git_sync::DeletedTrackedPaths::snapshot(&ctx.repo_root)?,
            staged_index_changes: git_sync::StagedIndexChanges::snapshot(&ctx.repo_root)?,
            dirty_file_contents: git_sync::DirtyFileContents::snapshot(&ctx.repo_root)?,
        })
    }

    fn print(&self, ctx: &RebaseContext) {
        println!("Repository root: {}", ctx.repo_root.display());
        println!("Original branch: {}", ctx.original_branch);
        println!("Dry run: {}", ctx.dry_run);
        println!("Auto rebase: {}", ctx.auto_rebase);
        println!(
            "Jujutsu workspace: {} ({})",
            if self.jj_state.present {
                "present"
            } else {
                "absent"
            },
            self.jj_state.repo_path.display()
        );
        if let Some(workspace_name) = &self.jj_state.workspace_name {
            println!(
                "Jujutsu workspace root: {} ({workspace_name})",
                self.jj_state.workspace_root.display()
            );
        }
    }
}

fn fetch_and_import(
    ctx: &RebaseContext,
    workflow_state: &WorkflowState,
    jj_workspace: &mut jj::JjWorkspace,
) -> Result<()> {
    let fetch = pollster::block_on(git_sync::fetch_and_import(
        &ctx.repo_root,
        &jj_workspace.repo,
        &ctx.original_branch,
        jj_workspace.workspace.workspace_name(),
    ))?;
    println!(
        "Fetched {}: {} git ref update(s), {} jj bookmark import(s), {} jj tag import(s)",
        fetch.remote,
        fetch.git_ref_updates,
        fetch.imported.changed_remote_bookmarks.len(),
        fetch.imported.changed_remote_tags.len()
    );

    if fetch.committed {
        jj_workspace.repo = fetch.repo;
        jj::sync_working_copy_state(&mut jj_workspace.workspace, &jj_workspace.repo)?;
        workflow_state
            .staged_index_changes
            .restore(&ctx.repo_root)?;
        workflow_state
            .deleted_tracked_paths
            .restore(&ctx.repo_root)?;
        workflow_state.dirty_file_contents.restore(&ctx.repo_root)?;
    }

    Ok(())
}

fn handle_changes(
    ctx: &RebaseContext,
    workflow_state: &WorkflowState,
    jj_workspace: &mut jj::JjWorkspace,
    changes: &changes::ChangeSet,
) -> Result<()> {
    match changes.state {
        ChangeState::None => {
            println!("No local or remote changes detected. Nothing to do");
        }
        ChangeState::LocalOnly => {
            println!("Only local changes detected. No rebase needed");
        }
        ChangeState::RemoteOnly | ChangeState::LocalAndRemote => {
            if matches!(changes.state, ChangeState::LocalAndRemote) {
                let stats = pollster::block_on(rebase::check_safety(&jj_workspace.repo, changes))?;
                println!(
                    "Safety check passed: {} target(s), {} descendant(s)",
                    stats.num_rebased_targets, stats.num_rebased_descendants
                );
            }
            let should_apply = ctx.auto_rebase || matches!(changes.state, ChangeState::RemoteOnly);
            let outcome = pollster::block_on(rebase::perform(
                &mut jj_workspace.workspace,
                &jj_workspace.repo,
                changes,
                ctx.dry_run,
                should_apply,
            ))?;
            if outcome.committed {
                println!("Successfully rebased local work onto {}", outcome.target);
            } else if ctx.dry_run {
                println!("[DRY RUN] Rebase onto {} would succeed", outcome.target);
            } else {
                println!("Rebase would be safe, but --no-auto-rebase is set. Skipping rebase");
            }
            println!(
                "Rebased targets: {}, descendants: {}, skipped: {}, abandoned empty: {}",
                outcome.stats.num_rebased_targets,
                outcome.stats.num_rebased_descendants,
                outcome.stats.num_skipped_rebases,
                outcome.stats.num_abandoned_empty
            );
            if outcome.committed {
                println!(
                    "Exported refs to git (failed bookmarks: {}, failed tags: {})",
                    outcome.exported_bookmarks, outcome.exported_tags
                );
                git_sync::restore_git_checkout(&ctx.repo_root, &ctx.original_branch)?;
                workflow_state
                    .staged_index_changes
                    .restore(&ctx.repo_root)?;
                workflow_state
                    .deleted_tracked_paths
                    .restore(&ctx.repo_root)?;
                workflow_state.dirty_file_contents.restore(&ctx.repo_root)?;
            }
        }
    }

    Ok(())
}
