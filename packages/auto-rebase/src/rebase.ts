import { logger, execSafe } from '@euvlok/shared';
import type { RebaseContext } from './context';
import { getRemoteBookmark } from './checks';

export async function checkRebaseSafety(
  ctx: RebaseContext,
): Promise<{ safe: boolean; rebaseAlreadyApplied: boolean }> {
  logger.info('Checking if rebase would be safe...');
  const target = await getRemoteBookmark(ctx.repoRoot);

  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Performing actual rebase in jj to show result...');
    const result = await execSafe(['jj', 'rebase', '-b', '@', '-d', target], {
      cwd: ctx.repoRoot,
    });
    if (result.exitCode === 0) {
      logger.success('  [DRY RUN] Rebase would succeed');
      logger.info('  [DRY RUN] Resulting jj log:');
      await execSafe(['jj', 'log', '-r', '@', '--limit', '5', '--no-graph'], {
        cwd: ctx.repoRoot,
      });
      await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });
      return { safe: true, rebaseAlreadyApplied: false };
    }
    logger.warn('  [DRY RUN] Rebase would have conflicts');
    await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });
    return { safe: false, rebaseAlreadyApplied: false };
  }

  const result = await execSafe(['jj', 'rebase', '-b', '@', '-d', target], {
    cwd: ctx.repoRoot,
  });

  if (result.exitCode === 0) {
    logger.success('Rebase would be safe (test rebase succeeded)');
    return { safe: true, rebaseAlreadyApplied: true };
  }

  const conflicts = /conflict/i.test(result.stderr + result.stdout);
  await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });

  if (conflicts) {
    logger.warn('Rebase would have conflicts. Aborting safety check');
    logger.info('Please resolve conflicts manually using standard Git commands:');
    logger.info('  git pull');
    return { safe: false, rebaseAlreadyApplied: false };
  }

  logger.success('Rebase appears safe (no conflicts detected)');
  return { safe: true, rebaseAlreadyApplied: false };
}

export async function performRebase(ctx: RebaseContext): Promise<void> {
  const target = await getRemoteBookmark(ctx.repoRoot);
  logger.info(`Rebasing current working copy onto ${target}...`);

  if (ctx.dryRun) {
    logger.info(`  [DRY RUN] Would run: jj rebase -b @ -d ${target}`);
    return;
  }

  const result = await execSafe(['jj', 'rebase', '-b', '@', '-d', target], {
    cwd: ctx.repoRoot,
  });

  if (result.exitCode === 0) {
    logger.success(`Successfully rebased onto ${target}`);
    return;
  }

  const conflicts = /conflict/i.test(result.stderr + result.stdout);
  if (conflicts) {
    logger.error('Rebase failed due to conflicts');
    logger.warn('Conflicts detected. Aborting rebase to prevent corruption');
    await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });
    logger.info('The repository has been restored to its original state');
    logger.info('Please resolve conflicts manually using standard Git commands:');
    logger.info('  git pull');
    logger.info(`Backup available at: ${ctx.backupFile}`);
    throw new Error('Rebase failed due to conflicts');
  }

  throw new Error(`Rebase failed for unknown reason: ${result.stderr}`);
}
