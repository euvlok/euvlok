//! Checkout selection integration tests for auto-rebase.

#[doc(hidden)]
pub mod common;

use anyhow::Result;
use common::{Fixture, git};

#[test]
fn non_master_branch_uses_matching_remote_bookmark() -> Result<()> {
    let fixture = Fixture::new()?;
    git(&fixture.upstream, &["switch", "-c", "feature/weird"])?;
    Fixture::commit_file(
        &fixture.upstream,
        "FEATURE.txt",
        "feature\n",
        "feature base",
    )?;
    fixture.push_upstream_branch("feature/weird")?;
    git(&fixture.work, &["fetch", "origin", "feature/weird"])?;
    git(&fixture.work, &["switch", "-c", "feature/weird"])?;
    git(
        &fixture.work,
        &["branch", "--set-upstream-to=origin/feature/weird"],
    )?;
    Fixture::commit_file(
        &fixture.work,
        "FEATURE_LOCAL.txt",
        "local\n",
        "feature local",
    )?;
    Fixture::commit_file(
        &fixture.upstream,
        "FEATURE_REMOTE.txt",
        "remote\n",
        "feature remote",
    )?;
    fixture.push_upstream_branch("feature/weird")?;

    let output = fixture.run_auto_rebase_on_branch("feature/weird")?;

    assert!(output.contains("Remote bookmark: feature/weird@origin"));
    assert!(output.contains("Change state: LocalAndRemote"));
    assert_eq!(fixture.current_checkout_name()?, "feature/weird");
    assert_eq!(
        fixture.rev_parse("HEAD^")?,
        fixture.rev_parse("origin/feature/weird")?
    );
    assert_eq!(fixture.read("FEATURE_LOCAL.txt")?, "local\n");
    assert_eq!(fixture.read("FEATURE_REMOTE.txt")?, "remote\n");
    assert_eq!(fixture.status()?, "");
    Ok(())
}

#[test]
fn detached_head_stays_detached_after_rebase() -> Result<()> {
    let fixture = Fixture::new()?;
    git(&fixture.work, &["switch", "--detach", "HEAD"])?;
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Original branch: HEAD"));
    assert_eq!(fixture.current_checkout_name()?, "HEAD");
    Ok(())
}
