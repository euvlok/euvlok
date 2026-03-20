import { $ } from 'bun';
import { logger, execSafe } from '@euvlok/shared';
import { join, basename } from 'pathe';
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

  const headResult = await execSafe(['git', '-C', ctx.repoRoot, 'rev-parse', 'HEAD']);
  if (headResult.exitCode !== 0) {
    logger.warn('Repository has no commits. Skipping backup creation');
    return '';
  }

  const bundleResult = await execSafe([
    'git',
    '-C',
    ctx.repoRoot,
    'bundle',
    'create',
    file,
    '--all',
  ]);
  if (bundleResult.exitCode !== 0) {
    throw new Error('Failed to create backup bundle');
  }

  logger.success(`Backup created: ${file}`);
  logger.warn(
    'Note: This backup contains commit history only, not uncommitted working directory changes',
  );
  logger.info(`To restore: git clone ${file} <destination>`);
  return file;
}
