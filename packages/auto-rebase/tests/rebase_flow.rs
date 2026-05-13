//! Rebase flow integration tests for auto-rebase.

#[doc(hidden)]
pub mod common;

use anyhow::Result;
use common::{Fixture, git};

#[test]
fn remote_only_advances_branch_to_origin() -> Result<()> {
    let fixture = Fixture::new()?;
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: RemoteOnly"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD")?,
        fixture.rev_parse("origin/master")?
    );
    assert_eq!(fixture.status()?, "");
    Ok(())
}

#[test]
fn local_and_remote_rebases_local_commit_on_origin() -> Result<()> {
    let fixture = Fixture::new()?;
    Fixture::commit_file(&fixture.work, "LOCAL.txt", "local\n", "local change")?;
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: LocalAndRemote"));
    assert!(fixture.work.join("LOCAL.txt").exists());
    assert!(fixture.work.join("REMOTE.txt").exists());
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD^")?,
        fixture.rev_parse("origin/master")?
    );
    assert_eq!(fixture.status()?, "");
    Ok(())
}

#[test]
fn force_pushed_remote_rewrite_rebases_local_commit() -> Result<()> {
    let fixture = Fixture::new()?;
    Fixture::commit_file(&fixture.work, "LOCAL.txt", "local\n", "local change")?;
    Fixture::commit_file(&fixture.upstream, "DOOMED.txt", "doomed\n", "doomed remote")?;
    fixture.push_upstream()?;
    git(&fixture.upstream, &["reset", "--hard", "HEAD~1"])?;
    Fixture::commit_file(
        &fixture.upstream,
        "REWRITTEN.txt",
        "rewritten\n",
        "rewritten remote",
    )?;
    git(&fixture.upstream, &["push", "--force", "origin", "master"])?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: LocalAndRemote"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD^")?,
        fixture.rev_parse("origin/master")?
    );
    assert_eq!(fixture.read("LOCAL.txt")?, "local\n");
    assert_eq!(fixture.read("REWRITTEN.txt")?, "rewritten\n");
    assert!(!fixture.work.join("DOOMED.txt").exists());
    assert_eq!(fixture.status()?, "");
    Ok(())
}

#[test]
fn git_commit_after_jj_workspace_exists_is_rebased() -> Result<()> {
    let fixture = Fixture::new()?;
    Fixture::commit_file(
        &fixture.upstream,
        "FIRST_REMOTE.txt",
        "first\n",
        "first remote",
    )?;
    fixture.push_upstream()?;

    fixture.run_auto_rebase()?;
    Fixture::commit_file(
        &fixture.work,
        "LATE_LOCAL.txt",
        "late local\n",
        "late local",
    )?;
    Fixture::commit_file(
        &fixture.upstream,
        "SECOND_REMOTE.txt",
        "second\n",
        "second remote",
    )?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: LocalAndRemote"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD^")?,
        fixture.rev_parse("origin/master")?
    );
    assert_eq!(fixture.read("LATE_LOCAL.txt")?, "late local\n");
    assert_eq!(fixture.read("SECOND_REMOTE.txt")?, "second\n");
    assert_eq!(fixture.status()?, "");
    Ok(())
}
