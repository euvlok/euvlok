//! Binary entry point for the auto-rebase command.

use anyhow::Result;
use auto_rebase::{Args, run};
use clap::Parser;

fn main() -> Result<()> {
    run(Args::parse())
}
