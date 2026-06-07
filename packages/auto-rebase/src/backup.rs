use crate::context::RebaseContext;
use anyhow::{Context, Result};
use fs_err as fs;
use gix::refs::Target;
use gix::refs::transaction::{Change, LogChange, PreviousValue, RefEdit, RefLog};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug)]
pub struct Backup {
    pub ref_name: Option<String>,
    pub manifest: Option<PathBuf>,
}

impl Backup {
    pub fn cleanup(&self, repo_root: &std::path::Path) -> Result<()> {
        if let Some(ref_name) = &self.ref_name {
            let repo = gix::open(repo_root).with_context(|| {
                format!("failed to open git repository at {}", repo_root.display())
            })?;
            let full_name = gix::refs::FullName::try_from(ref_name.as_str())
                .with_context(|| format!("invalid backup ref name '{ref_name}'"))?;
            repo.edit_reference(RefEdit {
                change: Change::Delete {
                    expected: PreviousValue::Any,
                    log: RefLog::AndReference,
                },
                name: full_name,
                deref: false,
            })
            .with_context(|| format!("failed to clean up backup ref {ref_name}"))?;
        }

        if let Some(manifest) = &self.manifest
            && manifest.try_exists().with_context(|| {
                format!("failed to inspect backup manifest {}", manifest.display())
            })?
        {
            fs::remove_file(manifest).with_context(|| {
                format!("failed to clean up backup manifest {}", manifest.display())
            })?;
        }

        Ok(())
    }
}

pub fn create(ctx: &RebaseContext) -> Result<Backup> {
    let repo = gix::open(&ctx.repo_root).with_context(|| {
        format!(
            "failed to open git repository for backup at {}",
            ctx.repo_root.display()
        )
    })?;
    let Ok(head_id) = repo.head_id() else {
        return Ok(Backup {
            ref_name: None,
            manifest: None,
        });
    };

    let repo_name = ctx
        .repo_root
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("repository");
    let backup_id = backup_id();
    let ref_name = format!(
        "refs/auto-rebase/backups/{}/{}",
        sanitize_ref_component(&ctx.original_branch),
        backup_id
    );
    let full_name = gix::refs::FullName::try_from(ref_name.as_str())
        .with_context(|| format!("invalid backup ref name '{ref_name}'"))?;
    repo.edit_reference(RefEdit {
        change: Change::Update {
            log: LogChange {
                message: "auto-rebase backup".into(),
                ..Default::default()
            },
            expected: PreviousValue::MustNotExist,
            new: Target::Object(head_id.detach()),
        },
        name: full_name,
        deref: false,
    })
    .with_context(|| format!("failed to create backup ref {ref_name}"))?;

    fs::create_dir_all(&ctx.backup_dir).with_context(|| {
        format!(
            "failed to create backup directory {}",
            ctx.backup_dir.display()
        )
    })?;
    let manifest = ctx
        .backup_dir
        .join(format!("{repo_name}-{backup_id}.auto-rebase-backup"));
    fs::write(
        &manifest,
        format!(
            "repo={}\nbranch={}\nhead={}\nref={}\n",
            ctx.repo_root.display(),
            ctx.original_branch,
            head_id,
            ref_name
        ),
    )
    .with_context(|| format!("failed to write backup manifest {}", manifest.display()))?;

    Ok(Backup {
        ref_name: Some(ref_name),
        manifest: Some(manifest),
    })
}

fn backup_id() -> String {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or_default();
    format!("{seconds}-{}", std::process::id())
}

fn sanitize_ref_component(value: &str) -> String {
    value
        .chars()
        .map(|ch| match ch {
            'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '_' => ch,
            _ => '-',
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::context::RebaseContext;

    #[test]
    fn sanitize_ref_component_replaces_ref_separators() {
        assert_eq!(sanitize_ref_component("feature/foo.bar"), "feature-foo-bar");
    }

    #[test]
    fn create_skips_repository_without_head() -> Result<()> {
        let dir = tempfile::tempdir()?;
        gix::init(dir.path())?;
        let ctx = RebaseContext::new(
            dir.path().to_path_buf(),
            "main".to_string(),
            true,
            true,
            dir.path().join("backups"),
        );

        let backup = create(&ctx)?;

        assert!(backup.ref_name.is_none());
        Ok(())
    }
}
