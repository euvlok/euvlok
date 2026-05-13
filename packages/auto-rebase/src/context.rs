use std::path::PathBuf;

#[derive(Debug)]
pub struct RebaseContext {
    pub repo_root: PathBuf,
    pub dry_run: bool,
    pub auto_rebase: bool,
    pub backup_dir: PathBuf,
    pub original_branch: String,
}

impl RebaseContext {
    #[must_use]
    pub const fn new(
        repo_root: PathBuf,
        original_branch: String,
        dry_run: bool,
        auto_rebase: bool,
        backup_dir: PathBuf,
    ) -> Self {
        Self {
            repo_root,
            dry_run,
            auto_rebase,
            backup_dir,
            original_branch,
        }
    }
}
