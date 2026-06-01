use clap::Parser;
use std::path::PathBuf;

#[derive(Debug, Parser)]
#[command(
    name = "auto-rebase",
    version,
    about = "Fetch remote changes and rebase local work when it is safe"
)]
/// Command line arguments for the auto-rebase tool.
pub struct Args {
    /// Branch to synchronize instead of the current branch.
    #[arg(short, long, value_name = "BRANCH")]
    pub branch: Option<String>,

    /// Check whether a rebase would be safe without committing changes.
    #[arg(long)]
    pub dry_run: bool,

    /// Fetch and inspect changes without automatically rebasing local work.
    #[arg(long = "no-auto-rebase", default_value_t = false)]
    pub no_auto_rebase: bool,

    /// Directory used for temporary backup manifests.
    #[arg(long, default_value_os_t = std::env::temp_dir(), value_name = "DIR")]
    pub backup_dir: PathBuf,
}
