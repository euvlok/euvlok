import { logger } from '@euvlok/shared';
import { $ } from 'bun';
import { basename, join } from 'pathe';
import { simpleGit } from 'simple-git';
import type { RebaseContext } from './context';

export async function createBackup(ctx: RebaseContext): Promise<string> {
  logger.info('Creating backup of current repository state...');

  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Would create backup bundle');
    return '';
  }

  await $`mkdir -p ${ctx.backupDir}`.quiet();

  const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 15);
  const repoName = basename(ctx.repoRoot);
  const file = join(ctx.backupDir, `${repoName}-backup-${timestamp}.gitbundle`);

  const git = simpleGit(ctx.repoRoot);
  const hasHead = await git
    .revparse(['HEAD'])
    .then(() => true)
    .catch(() => false);
  if (!hasHead) {
    logger.warn('Repository has no commits. Skipping backup creation');
    return '';
  }

  await git.raw(['bundle', 'create', file, '--all']).catch(() => {
    throw new Error('Failed to create backup bundle');
  });

  logger.success(`Backup created: ${file}`);
  logger.warn(
    'Note: This backup contains commit history only, not uncommitted working directory changes',
  );
  logger.info(`To restore: git clone ${file} <destination>`);
  return file;
}
