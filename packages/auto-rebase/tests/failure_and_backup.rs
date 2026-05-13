//! Failure handling and backup integration tests for auto-rebase.

#[doc(hidden)]
pub mod common;

use anyhow::{Context, Result};
use common::{Fixture, backup_ref_from_output, git};

#[test]
fn conflicting_rebase_fails_without_dirtying_checkout() -> Result<()> {
    let fixture = Fixture::new()?;
    Fixture::commit_file(&fixture.work, "README.md", "local\n", "local readme")?;
    Fixture::commit_file(&fixture.upstream, "README.md", "remote\n", "remote readme")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase_err()?;

    assert!(output.contains("rebase would introduce conflicts"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(fixture.read("README.md")?, "local\n");
    assert_eq!(fixture.status()?, "");
    Ok(())
}

#[test]
fn successful_rebase_cleans_up_backup_ref_and_manifest() -> Result<()> {
    let fixture = Fixture::new()?;
    let backup_dir = fixture.backup_dir();
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase_args(&[
        "--backup-dir",
        backup_dir.to_str().context("non-utf8 backup path")?,
    ])?;

    assert!(output.contains("Backup ref: refs/auto-rebase/backups/master/"));
    assert_eq!(
        git(
            &fixture.work,
            &[
                "for-each-ref",
                "--format=%(refname)",
                "refs/auto-rebase/backups"
            ],
        )?,
        ""
    );
    assert_eq!(std::fs::read_dir(&backup_dir)?.count(), 0);
    assert_eq!(
        fixture.rev_parse("HEAD")?,
        fixture.rev_parse("origin/master")?
    );
    Ok(())
}

#[test]
fn failed_conflict_keeps_backup_ref_and_manifest() -> Result<()> {
    let fixture = Fixture::new()?;
    let backup_dir = fixture.backup_dir();
    Fixture::commit_file(&fixture.work, "README.md", "local\n", "local readme")?;
    let original_head = fixture.rev_parse("HEAD")?;
    Fixture::commit_file(&fixture.upstream, "README.md", "remote\n", "remote readme")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase_err_args(&[
        "--backup-dir",
        backup_dir.to_str().context("non-utf8 backup path")?,
    ])?;
    let backup_ref = backup_ref_from_output(&output)?;

    assert!(output.contains("rebase would introduce conflicts"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(fixture.read("README.md")?, "local\n");
    assert_eq!(fixture.status()?, "");
    assert_eq!(fixture.rev_parse(backup_ref)?, original_head);
    let manifests = std::fs::read_dir(&backup_dir)?.collect::<Result<Vec<_>, _>>()?;
    assert_eq!(manifests.len(), 1);
    let manifest = std::fs::read_to_string(manifests[0].path())?;
    assert!(manifest.contains(&format!("head={original_head}")));
    assert!(manifest.contains(&format!("ref={backup_ref}")));
    Ok(())
}
