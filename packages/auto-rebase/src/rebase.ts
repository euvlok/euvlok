import { execSafe, logger } from '@euvlok/shared';
import { getRemoteBookmark } from './checks';
import type { RebaseContext } from './context';

function hasConflictOutput(result: { stdout: string; stderr: string }): boolean {
  return /conflict/i.test(result.stderr + result.stdout);
}

function successResult(rebaseAlreadyApplied: boolean) {
  return { safe: true, rebaseAlreadyApplied };
}

function unsafeResult() {
  return { safe: false, rebaseAlreadyApplied: false };
}

async function rebaseOnto(ctx: RebaseContext, target: string) {
  return execSafe(['jj', 'rebase', '-b', '@', '-d', target], {
    cwd: ctx.repoRoot,
  });
}

export async function checkRebaseSafety(
  ctx: RebaseContext,
): Promise<{ safe: boolean; rebaseAlreadyApplied: boolean }> {
  logger.info('Checking if rebase would be safe...');
  const target = await getRemoteBookmark(ctx.repoRoot);

  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Performing actual rebase in jj to show result...');
    const result = await rebaseOnto(ctx, target);
    if (result.exitCode === 0) {
      logger.success('  [DRY RUN] Rebase would succeed');
      logger.info('  [DRY RUN] Resulting jj log:');
      await execSafe(['jj', 'log', '-r', '@', '--limit', '5', '--no-graph'], {
        cwd: ctx.repoRoot,
      });
      await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });
      return successResult(false);
    }
    logger.warn('  [DRY RUN] Rebase would have conflicts');
    await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });
    return unsafeResult();
  }

  const result = await rebaseOnto(ctx, target);

  if (result.exitCode === 0) {
    logger.success('Rebase would be safe (test rebase succeeded)');
    return successResult(true);
  }

  await execSafe(['jj', 'undo'], { cwd: ctx.repoRoot });

  if (hasConflictOutput(result)) {
    logger.warn('Rebase would have conflicts. Aborting safety check');
    logger.info('Please resolve conflicts manually using standard Git commands:');
    logger.info('  git pull');
    return unsafeResult();
  }

  logger.success('Rebase appears safe (no conflicts detected)');
  return successResult(false);
}

export async function performRebase(ctx: RebaseContext): Promise<void> {
  const target = await getRemoteBookmark(ctx.repoRoot);
  logger.info(`Rebasing current working copy onto ${target}...`);

  if (ctx.dryRun) {
    logger.info(`  [DRY RUN] Would run: jj rebase -b @ -d ${target}`);
    return;
  }

  const result = await rebaseOnto(ctx, target);

  if (result.exitCode === 0) {
    logger.success(`Successfully rebased onto ${target}`);
    return;
  }

  if (hasConflictOutput(result)) {
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
