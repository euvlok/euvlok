//! Dirty worktree preservation integration tests for auto-rebase.

#[doc(hidden)]
pub mod common;

use anyhow::Result;
use common::{Fixture, git, write};

#[test]
fn uncommitted_staged_and_unstaged_file_contents_survive_rebase() -> Result<()> {
    let fixture = Fixture::new()?;
    write(fixture.work.join("STAGED.txt"), "staged edit\n")?;
    git(&fixture.work, &["add", "STAGED.txt"])?;
    write(fixture.work.join("UNSTAGED.txt"), "unstaged edit\n")?;
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: RemoteOnly"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(fixture.read("STAGED.txt")?, "staged edit\n");
    assert_eq!(fixture.read("UNSTAGED.txt")?, "unstaged edit\n");
    assert_eq!(fixture.read("REMOTE.txt")?, "remote\n");
    assert_eq!(fixture.status()?, "M  STAGED.txt\n M UNSTAGED.txt\n");
    Ok(())
}

#[test]
fn dirty_tracked_file_changed_by_remote_survives_remote_only_rebase() -> Result<()> {
    let fixture = Fixture::new()?;
    write(fixture.work.join("README.md"), "local uncommitted readme\n")?;
    Fixture::commit_file(
        &fixture.upstream,
        "README.md",
        "remote readme\n",
        "remote readme",
    )?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: RemoteOnly"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD")?,
        fixture.rev_parse("origin/master")?
    );
    assert_eq!(fixture.read("README.md")?, "local uncommitted readme\n");
    assert_eq!(fixture.status()?, " M README.md\n");
    Ok(())
}

#[test]
fn untracked_file_collision_with_remote_add_preserves_local_content() -> Result<()> {
    let fixture = Fixture::new()?;
    write(fixture.work.join("COLLIDE.txt"), "local untracked\n")?;
    Fixture::commit_file(
        &fixture.upstream,
        "COLLIDE.txt",
        "remote tracked\n",
        "remote tracked collision",
    )?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: RemoteOnly"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD")?,
        fixture.rev_parse("origin/master")?
    );
    assert_eq!(fixture.read("COLLIDE.txt")?, "local untracked\n");
    assert_eq!(fixture.status()?, " M COLLIDE.txt\n");
    Ok(())
}

#[test]
fn staged_delete_and_unstaged_edit_survive_rebase() -> Result<()> {
    let fixture = Fixture::new()?;
    Fixture::commit_file(
        &fixture.work,
        "DELETE_TRACKED.txt",
        "delete base\n",
        "add delete target",
    )?;
    Fixture::commit_file(
        &fixture.work,
        "EDIT_TRACKED.txt",
        "edit base\n",
        "add edit target",
    )?;
    std::fs::remove_file(fixture.work.join("DELETE_TRACKED.txt"))?;
    git(&fixture.work, &["add", "DELETE_TRACKED.txt"])?;
    write(fixture.work.join("EDIT_TRACKED.txt"), "edited unstaged\n")?;
    Fixture::commit_file(
        &fixture.upstream,
        "REMOTE_DIRTY.txt",
        "remote\n",
        "remote while dirty",
    )?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: LocalAndRemote"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert_eq!(
        fixture.rev_parse("HEAD^^")?,
        fixture.rev_parse("origin/master")?
    );
    assert!(
        !fixture.work.join("DELETE_TRACKED.txt").exists(),
        "unexpected status:\n{}\ncontent:\n{}",
        fixture.status()?,
        fixture.read("DELETE_TRACKED.txt").unwrap_or_default()
    );
    assert_eq!(fixture.read("EDIT_TRACKED.txt")?, "edited unstaged\n");
    assert_eq!(fixture.read("REMOTE_DIRTY.txt")?, "remote\n");
    assert_eq!(
        fixture.status()?,
        "D  DELETE_TRACKED.txt\n M EDIT_TRACKED.txt\n"
    );
    Ok(())
}

#[test]
fn staged_rename_survives_rebase_as_staged_rename() -> Result<()> {
    let fixture = Fixture::new()?;
    git(&fixture.work, &["mv", "README.md", "README_RENAMED.md"])?;
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: RemoteOnly"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert!(!fixture.work.join("README.md").exists());
    assert_eq!(fixture.read("README_RENAMED.md")?, "base\n");
    assert_eq!(fixture.read("REMOTE.txt")?, "remote\n");
    assert_eq!(fixture.status()?, "R  README.md -> README_RENAMED.md\n");
    Ok(())
}

#[test]
fn renamed_and_deleted_files_survive_rebase() -> Result<()> {
    let fixture = Fixture::new()?;
    std::fs::rename(
        fixture.work.join("README.md"),
        fixture.work.join("RENAMED.md"),
    )?;
    std::fs::remove_file(fixture.work.join("DELETE_ME.txt"))?;
    Fixture::commit_all(&fixture.work, "rename and delete")?;
    Fixture::commit_file(&fixture.upstream, "REMOTE.txt", "remote\n", "remote change")?;
    fixture.push_upstream()?;

    let output = fixture.run_auto_rebase()?;

    assert!(output.contains("Change state: LocalAndRemote"));
    assert_eq!(fixture.current_checkout_name()?, "master");
    assert!(!fixture.work.join("README.md").exists());
    assert!(!fixture.work.join("DELETE_ME.txt").exists());
    assert_eq!(fixture.read("RENAMED.md")?, "base\n");
    assert_eq!(fixture.read("REMOTE.txt")?, "remote\n");
    assert_eq!(fixture.status()?, "");
    Ok(())
}
