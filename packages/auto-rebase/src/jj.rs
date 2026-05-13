use anyhow::{Context, Result};
use jj_lib::config::{ConfigLayer, ConfigSource, StackedConfig};
use jj_lib::repo::{ReadonlyRepo, Repo, StoreFactories};
use jj_lib::settings::UserSettings;
use jj_lib::workspace::{Workspace, default_working_copy_factories};
use std::path::{Path, PathBuf};
use std::sync::Arc;

pub struct JjWorkspace {
    pub workspace: Workspace,
    pub repo: Arc<ReadonlyRepo>,
}

impl std::fmt::Debug for JjWorkspace {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter
            .debug_struct("JjWorkspace")
            .field("workspace_name", &self.workspace.workspace_name())
            .finish_non_exhaustive()
    }
}

#[derive(Debug)]
pub struct JjWorkspaceState {
    pub repo_path: PathBuf,
    pub workspace_root: PathBuf,
    pub workspace_name: Option<String>,
    pub present: bool,
}

pub fn inspect(root: &Path) -> Result<JjWorkspaceState> {
    let repo_path = root.join(".jj/repo");
    if !repo_path.exists() {
        return Ok(JjWorkspaceState {
            present: false,
            repo_path,
            workspace_root: root.to_path_buf(),
            workspace_name: None,
        });
    }

    let loaded = load(root)?;
    let workspace = loaded.workspace;

    Ok(JjWorkspaceState {
        present: true,
        repo_path: workspace.repo_path().to_path_buf(),
        workspace_root: workspace.workspace_root().to_path_buf(),
        workspace_name: Some(workspace.workspace_name().as_str().to_owned()),
    })
}

pub fn load(root: &Path) -> Result<JjWorkspace> {
    let settings = workspace_settings()?;
    let store_factories = StoreFactories::default();
    let working_copy_factories = default_working_copy_factories();
    let workspace = Workspace::load(&settings, root, &store_factories, &working_copy_factories)
        .with_context(|| format!("failed to load jj workspace at {}", root.display()))?;
    let repo = pollster::block_on(workspace.repo_loader().load_at_head()).with_context(|| {
        format!(
            "failed to load jj repo at {}",
            workspace.repo_path().display()
        )
    })?;

    Ok(JjWorkspace { workspace, repo })
}

pub fn load_or_init(root: &Path, branch: &str) -> Result<JjWorkspace> {
    if root.join(".jj/repo").exists() {
        return load(root);
    }

    let settings = workspace_settings()?;
    let git_repo = gix::open(root)
        .with_context(|| format!("failed to open git repository at {}", root.display()))?;
    let git_dir = git_repo.git_dir().to_path_buf();
    let (mut workspace, repo) =
        pollster::block_on(Workspace::init_external_git(&settings, root, &git_dir))
            .with_context(|| format!("failed to initialize jj workspace at {}", root.display()))?;
    let import_options = crate::git_sync::import_options(&settings)?;
    let mut tx = repo.start_transaction();
    pollster::block_on(async {
        jj_lib::git::import_refs(tx.repo_mut(), &import_options).await?;
        jj_lib::git::import_head(tx.repo_mut()).await?;
        crate::git_sync::track_remote_branch(tx.repo_mut(), branch)?;
        if let Some(head_id) = tx.repo().view().git_head().as_normal().cloned() {
            let head_commit = tx.repo().store().get_commit_async(&head_id).await?;
            tx.repo_mut()
                .check_out(workspace.workspace_name().to_owned(), &head_commit)
                .await?;
            tx.repo_mut().rebase_descendants().await?;
        }
        Ok::<_, anyhow::Error>(())
    })
    .context("failed to import existing git refs into new jj workspace")?;

    let repo = if tx.repo().has_changes() {
        pollster::block_on(tx.commit("initialize jj from git refs"))
            .context("failed to commit initialized jj refs")?
    } else {
        repo
    };
    let working_copy_id = repo
        .view()
        .get_wc_commit_id(workspace.workspace_name())
        .context("new jj workspace has no working-copy commit")?;
    let working_copy = pollster::block_on(repo.store().get_commit_async(working_copy_id))
        .context("failed to load initialized jj working-copy commit")?;
    pollster::block_on(workspace.check_out(repo.op_id().clone(), None, &working_copy))
        .context("failed to align initialized jj working-copy state")?;

    Ok(JjWorkspace { workspace, repo })
}

pub fn sync_working_copy_state(workspace: &mut Workspace, repo: &ReadonlyRepo) -> Result<()> {
    let working_copy_id = repo
        .view()
        .get_wc_commit_id(workspace.workspace_name())
        .with_context(|| {
            format!(
                "jj workspace '{}' has no working-copy commit",
                workspace.workspace_name().as_str()
            )
        })?;
    let working_copy = pollster::block_on(repo.store().get_commit_async(working_copy_id))
        .context("failed to load jj working-copy commit")?;
    pollster::block_on(workspace.check_out(repo.op_id().clone(), None, &working_copy))
        .context("failed to sync jj working-copy state")?;
    Ok(())
}

pub fn workspace_settings() -> Result<UserSettings> {
    let mut config = StackedConfig::with_defaults();
    let mut layer = ConfigLayer::empty(ConfigSource::User);
    layer
        .set_value("user.name", "auto-rebase")
        .context("failed to set jj user.name fallback")?;
    layer
        .set_value("user.email", "auto-rebase@localhost")
        .context("failed to set jj user.email fallback")?;
    config.add_layer(layer);

    UserSettings::from_config(config).context("failed to build jj user settings")
}
