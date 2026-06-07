use crate::constants::DEFAULT_REMOTE;
use crate::jj;
use anyhow::{Context, Result, bail};
use fs_err as fs;
use gix::bstr::{BStr, ByteSlice};
use gix::refs::Target;
use gix::refs::transaction::{Change, LogChange, PreviousValue, RefEdit};
use gix::remote::Direction;
use gix::remote::fetch::{RefLogMessage, Status, Tags, refs::update::Mode};
use gix::remote::ref_map::Options as FetchOptions;
use gix::status::Item;
use gix::status::plumbing::index_as_worktree_with_renames::Summary;
use jj_lib::git::{GitExportStats, GitImportOptions, GitImportStats};
use jj_lib::ref_name::{RefName, RemoteName, WorkspaceName};
use jj_lib::repo::{ReadonlyRepo, Repo};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::sync::atomic::AtomicBool;

#[derive(Debug)]
pub struct FetchImportOutcome {
    pub repo: Arc<ReadonlyRepo>,
    pub remote: String,
    pub git_ref_updates: usize,
    pub imported: GitImportStats,
    pub committed: bool,
}

#[derive(Debug)]
pub struct DeletedTrackedPaths {
    paths: Vec<PathBuf>,
}

#[derive(Debug)]
pub struct DirtyFileContents {
    files: Vec<DirtyFile>,
}

#[derive(Debug)]
pub struct StagedIndexChanges {
    changes: Vec<StagedIndexChange>,
}

#[derive(Debug)]
struct DirtyFile {
    path: PathBuf,
    contents: Vec<u8>,
}

#[derive(Debug)]
enum StagedIndexChange {
    Upsert(StagedEntry),
    Delete(Vec<u8>),
}

#[derive(Debug)]
struct StagedEntry {
    path: Vec<u8>,
    stat: gix::index::entry::Stat,
    id: gix::ObjectId,
    flags: gix::index::entry::Flags,
    mode: gix::index::entry::Mode,
}

impl DeletedTrackedPaths {
    pub fn snapshot(root: &Path) -> Result<Self> {
        let git_repo = gix::open(root)
            .with_context(|| format!("failed to open git repository at {}", root.display()))?;
        let mut paths = Vec::new();
        let mut status = git_repo
            .status(gix::progress::Discard)?
            .into_iter(Vec::<gix::bstr::BString>::new())?;
        for item in &mut status {
            match item.context("failed to read git status item")? {
                Item::TreeIndex(gix::diff::index::Change::Deletion { location, .. }) => {
                    paths.push(repo_path(location.as_ref()));
                }
                Item::TreeIndex(gix::diff::index::Change::Rewrite {
                    source_location,
                    copy,
                    ..
                }) if !copy => {
                    paths.push(repo_path(source_location.as_ref()));
                }
                Item::IndexWorktree(item) if item.summary() == Some(Summary::Removed) => {
                    paths.push(repo_path(item.rela_path()));
                }
                _ => {}
            }
        }

        Ok(Self { paths })
    }

    pub fn restore(&self, root: &Path) -> Result<()> {
        for path in &self.paths {
            let fs_path = root.join(path);
            if fs_path.try_exists().with_context(|| {
                format!("failed to inspect preserved deletion {}", fs_path.display())
            })? {
                fs::remove_file(&fs_path).with_context(|| {
                    format!(
                        "failed to restore deleted file state for {}",
                        fs_path.display()
                    )
                })?;
            }
        }

        Ok(())
    }
}

impl StagedIndexChanges {
    pub fn snapshot(root: &Path) -> Result<Self> {
        let git_repo = gix::open(root)
            .with_context(|| format!("failed to open git repository at {}", root.display()))?;
        let index = git_repo
            .open_index()
            .with_context(|| format!("failed to open git index at {}", root.display()))?;
        let mut changes = Vec::new();
        let mut status = git_repo
            .status(gix::progress::Discard)?
            .into_iter(Vec::<gix::bstr::BString>::new())?;

        for item in &mut status {
            match item.context("failed to read git status item")? {
                Item::TreeIndex(gix::diff::index::Change::Deletion { location, .. }) => {
                    changes.push(StagedIndexChange::Delete(location.as_ref().to_vec()));
                }
                Item::TreeIndex(
                    gix::diff::index::Change::Addition { index: idx, .. }
                    | gix::diff::index::Change::Modification { index: idx, .. },
                ) => {
                    changes.push(StagedIndexChange::Upsert(staged_entry(&index, idx)?));
                }
                Item::TreeIndex(gix::diff::index::Change::Rewrite {
                    source_location,
                    index: idx,
                    copy,
                    ..
                }) => {
                    if !copy {
                        changes.push(StagedIndexChange::Delete(source_location.as_ref().to_vec()));
                    }
                    changes.push(StagedIndexChange::Upsert(staged_entry(&index, idx)?));
                }
                _ => {}
            }
        }

        Ok(Self { changes })
    }

    pub fn restore(&self, root: &Path) -> Result<()> {
        if self.changes.is_empty() {
            return Ok(());
        }

        let git_repo = gix::open(root)
            .with_context(|| format!("failed to open git repository at {}", root.display()))?;
        let mut index = git_repo
            .open_index()
            .with_context(|| format!("failed to open git index at {}", root.display()))?;
        for change in &self.changes {
            match change {
                StagedIndexChange::Delete(path) => {
                    remove_index_bstr(&mut index, path.as_slice().as_bstr());
                }
                StagedIndexChange::Upsert(entry) => {
                    remove_index_bstr(&mut index, entry.path.as_slice().as_bstr());
                    index.dangerously_push_entry(
                        entry.stat,
                        entry.id,
                        entry.flags,
                        entry.mode,
                        entry.path.as_slice().as_bstr(),
                    );
                }
            }
        }
        index.remove_tree();
        index.sort_entries();
        index
            .write(gix::index::write::Options::default())
            .context("failed to write restored staged index state")?;

        Ok(())
    }
}

impl DirtyFileContents {
    pub fn snapshot(root: &Path) -> Result<Self> {
        let git_repo = gix::open(root)
            .with_context(|| format!("failed to open git repository at {}", root.display()))?;
        let mut files = Vec::new();
        let mut status = git_repo
            .status(gix::progress::Discard)?
            .into_iter(Vec::<gix::bstr::BString>::new())?;
        for item in &mut status {
            let path = match item.context("failed to read git status item")? {
                Item::TreeIndex(
                    gix::diff::index::Change::Addition { location, .. }
                    | gix::diff::index::Change::Modification { location, .. }
                    | gix::diff::index::Change::Rewrite { location, .. },
                ) => repo_path(location.as_ref()),
                Item::IndexWorktree(item) if item.summary() != Some(Summary::Removed) => {
                    repo_path(item.rela_path())
                }
                _ => continue,
            };

            let fs_path = root.join(&path);
            if fs_path.is_file() {
                files.push(DirtyFile {
                    path,
                    contents: fs::read(&fs_path).with_context(|| {
                        format!("failed to snapshot dirty file {}", fs_path.display())
                    })?,
                });
            }
        }

        Ok(Self { files })
    }

    pub fn restore(&self, root: &Path) -> Result<()> {
        for file in &self.files {
            let fs_path = root.join(&file.path);
            if let Some(parent) = fs_path.parent() {
                fs::create_dir_all(parent).with_context(|| {
                    format!("failed to create parent directory {}", parent.display())
                })?;
            }
            fs::write(&fs_path, &file.contents)
                .with_context(|| format!("failed to restore dirty file {}", fs_path.display()))?;
        }

        Ok(())
    }
}

fn repo_path(path: &BStr) -> PathBuf {
    path.to_path_lossy().into_owned()
}

fn staged_entry(index: &gix::index::File, entry_index: usize) -> Result<StagedEntry> {
    let entry = index
        .entries()
        .get(entry_index)
        .with_context(|| format!("missing staged index entry {entry_index}"))?;
    Ok(StagedEntry {
        path: entry.path(index).to_vec(),
        stat: entry.stat,
        id: entry.id,
        flags: entry.flags,
        mode: entry.mode,
    })
}

fn remove_index_bstr(index: &mut gix::index::File, path: &BStr) {
    index.remove_entries(|_, entry_path, _| entry_path == path);
}

pub fn fetch_remote(root: &Path, remote_name: &str) -> Result<usize> {
    let git_repo = gix::open(root)
        .with_context(|| format!("failed to open git repository at {}", root.display()))?;
    let mut remote = git_repo
        .find_fetch_remote(Some(remote_name.as_bytes().as_bstr()))
        .with_context(|| format!("failed to find git remote '{remote_name}'"))?;

    if remote.refspecs(Direction::Fetch).is_empty() {
        let spec = format!("+refs/heads/*:refs/remotes/{remote_name}/*");
        remote = remote
            .with_refspecs([spec.as_str()], Direction::Fetch)
            .context("failed to install default fetch refspec")?;
    }
    remote = remote.with_fetch_tags(Tags::None);

    let mut progress = gix::progress::Discard;
    let should_interrupt = AtomicBool::new(false);
    let connection = remote
        .connect(Direction::Fetch)
        .with_context(|| format!("failed to connect to git remote '{remote_name}'"))?;
    let fetch = connection
        .prepare_fetch(&mut progress, FetchOptions::default())
        .context("failed to prepare in-process git fetch")?
        .with_reflog_message(RefLogMessage::Prefixed {
            action: "auto-rebase fetch".to_owned(),
        });
    let outcome = fetch
        .receive(&mut progress, &should_interrupt)
        .context("failed to fetch remote refs with gix")?;

    let updates = match &outcome.status {
        Status::NoPackReceived { update_refs, .. } | Status::Change { update_refs, .. } => {
            rejected_updates(update_refs)?;
            update_refs
                .updates
                .iter()
                .filter(|update| !matches!(update.mode, Mode::NoChangeNeeded))
                .count()
        }
    };

    Ok(updates)
}

#[allow(clippy::future_not_send)]
pub async fn fetch_and_import(
    root: &Path,
    repo: &Arc<ReadonlyRepo>,
    branch: &str,
    workspace_name: &WorkspaceName,
) -> Result<FetchImportOutcome> {
    let remote = DEFAULT_REMOTE.to_owned();
    let git_ref_updates = fetch_remote(root, &remote)?;

    let settings = jj::workspace_settings()?;
    let import_options = import_options(&settings)?;
    let mut tx = repo.start_transaction();
    let imported = jj_lib::git::import_refs(tx.repo_mut(), &import_options)
        .await
        .context("failed to import fetched git refs into jj")?;
    jj_lib::git::import_head(tx.repo_mut())
        .await
        .context("failed to import git HEAD into jj")?;
    track_remote_branch(tx.repo_mut(), branch)?;
    align_workspace_to_git_head(tx.repo_mut(), branch, workspace_name).await?;

    let committed = tx.repo().has_changes();
    let repo = if committed {
        tx.commit("import fetched git refs")
            .await
            .context("failed to commit fetched refs into jj")?
    } else {
        repo.clone()
    };

    Ok(FetchImportOutcome {
        repo,
        remote,
        git_ref_updates,
        imported,
        committed,
    })
}

pub fn track_remote_branch(mut_repo: &mut jj_lib::repo::MutableRepo, branch: &str) -> Result<()> {
    if branch == crate::repo::DETACHED_HEAD {
        return Ok(());
    }

    let name = RefName::new(branch);
    let remote = RemoteName::new(DEFAULT_REMOTE);
    let remote_ref = mut_repo
        .view()
        .get_remote_bookmark(name.to_remote_symbol(remote));
    if remote_ref.target.is_absent() {
        return Ok(());
    }

    mut_repo
        .track_remote_bookmark(name.to_remote_symbol(remote))
        .with_context(|| format!("failed to track {branch}@{DEFAULT_REMOTE}"))?;
    Ok(())
}

#[allow(clippy::future_not_send)]
async fn align_workspace_to_git_head(
    mut_repo: &mut jj_lib::repo::MutableRepo,
    branch: &str,
    workspace_name: &WorkspaceName,
) -> Result<()> {
    if branch == crate::repo::DETACHED_HEAD {
        return Ok(());
    }

    let Some(head_id) = mut_repo.view().git_head().as_normal().cloned() else {
        return Ok(());
    };
    let head_commit = mut_repo
        .store()
        .get_commit_async(&head_id)
        .await
        .context("failed to load imported git HEAD commit")?;
    mut_repo
        .check_out(workspace_name.to_owned(), &head_commit)
        .await
        .context("failed to align jj workspace with imported git HEAD")?;
    mut_repo
        .rebase_descendants()
        .await
        .context("failed to rebase descendants after aligning git HEAD")?;

    Ok(())
}

pub fn export_refs(mut_repo: &mut jj_lib::repo::MutableRepo) -> Result<GitExportStats> {
    jj_lib::git::export_refs(mut_repo).context("failed to export jj refs to git")
}

pub fn restore_git_checkout(root: &Path, branch: &str) -> Result<()> {
    if branch == crate::repo::DETACHED_HEAD {
        return Ok(());
    }

    let git_repo = gix::open(root)
        .with_context(|| format!("failed to open git repository at {}", root.display()))?;
    let branch_ref = format!("refs/heads/{branch}");
    let branch_ref_name = gix::refs::FullName::try_from(branch_ref.as_str())
        .with_context(|| format!("invalid branch ref name '{branch_ref}'"))?;
    let head_ref_name = gix::refs::FullName::try_from("HEAD").context("invalid HEAD ref name")?;
    git_repo
        .edit_reference(RefEdit {
            change: Change::Update {
                log: LogChange {
                    message: "auto-rebase restore checkout".into(),
                    ..Default::default()
                },
                expected: PreviousValue::Any,
                new: Target::Symbolic(branch_ref_name),
            },
            name: head_ref_name,
            deref: false,
        })
        .context("failed to restore symbolic git HEAD")?;

    let commit_id = git_repo
        .find_reference(branch_ref.as_str())
        .with_context(|| format!("failed to find restored branch '{branch}'"))?
        .into_fully_peeled_id()
        .context("failed to resolve restored branch commit")?;
    let tree_id = commit_id
        .object()
        .context("failed to load restored branch commit")?
        .try_into_commit()
        .context("restored branch does not point to a commit")?
        .tree_id()
        .context("failed to resolve restored branch tree")?
        .detach();
    let mut index = git_repo
        .index_from_tree(&tree_id)
        .context("failed to rebuild git index from restored branch")?;
    index
        .write(gix::index::write::Options::default())
        .context("failed to write rebuilt git index")?;

    Ok(())
}

pub fn import_options(settings: &jj_lib::settings::UserSettings) -> Result<GitImportOptions> {
    let git_settings = jj_lib::git::GitSettings::from_settings(settings)
        .context("failed to read jj git import settings")?;
    Ok(GitImportOptions {
        abandon_unreachable_commits: git_settings.abandon_unreachable_commits,
        record_synthetic_predecessors: git_settings.record_synthetic_predecessors,
        remote_auto_track_bookmarks: Default::default(),
    })
}

fn rejected_updates(outcome: &gix::remote::fetch::refs::update::Outcome) -> Result<()> {
    let rejected = outcome
        .updates
        .iter()
        .filter(|update| {
            matches!(
                update.mode,
                Mode::RejectedSourceObjectNotFound { .. }
                    | Mode::RejectedTagUpdate
                    | Mode::RejectedNonFastForward
                    | Mode::RejectedToReplaceWithUnborn
                    | Mode::RejectedCurrentlyCheckedOut { .. }
            )
        })
        .map(|update| update.mode.to_string())
        .collect::<Vec<_>>();

    if rejected.is_empty() {
        Ok(())
    } else {
        bail!("git fetch rejected ref updates: {}", rejected.join(", "))
    }
}
