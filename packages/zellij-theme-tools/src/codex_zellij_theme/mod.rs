mod mcp;
mod startup_pane_color;
mod trust_overlay;

use std::ffi::OsString;

use clap::Parser;

use crate::{Result, codex_bin, run_inherit};

use startup_pane_color::StartupPaneColor;
use trust_overlay::create_trust_overlay;

#[derive(Debug, Parser)]
#[command(
    name = "codex-zellij-theme",
    version,
    about = "Run Codex with a trusted config overlay inside a themed Zellij pane",
    disable_help_flag = true
)]
struct Cli {
    /// Arguments forwarded to Codex.
    #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
    codex_args: Vec<OsString>,
}

/// Runs `codex-zellij-theme`.
///
/// # Errors
///
/// Returns an error if the trust overlay cannot be created or Codex cannot be
/// executed.
pub fn run() -> Result<i32> {
    let cli = Cli::parse();

    let _startup_pane_color = StartupPaneColor::start();

    let overlay = create_trust_overlay()?;
    let codex = codex_bin()?;
    let command = duct::cmd(codex, cli.codex_args)
        .env("CODEX_HOME", overlay.path())
        .unchecked();
    run_inherit(&command)
}

#[cfg(test)]
mod tests {
    use clap::error::ErrorKind;

    use super::*;

    #[test]
    fn cli_forwards_codex_help_and_hyphenated_args() {
        let cli = Cli::try_parse_from(["codex-zellij-theme", "--help", "--model", "gpt-5", "run"])
            .expect("parse cli");

        assert_eq!(
            cli.codex_args,
            [
                OsString::from("--help"),
                OsString::from("--model"),
                OsString::from("gpt-5"),
                OsString::from("run"),
            ]
        );
    }

    #[test]
    fn cli_owns_version_output() {
        let err = Cli::try_parse_from(["codex-zellij-theme", "--version"]).expect_err("version");

        assert_eq!(err.kind(), ErrorKind::DisplayVersion);
    }
}
