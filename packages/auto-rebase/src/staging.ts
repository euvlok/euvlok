import { $ } from 'bun';
import { logger, execSafe } from '@euvlok/shared';

export async function restoreStaging(
  root: string,
  stagedDiffPath: string,
  originalStagedFiles: string,
): Promise<void> {
  logger.info('Restoring original staging state...');
  await execSafe(['git', '-C', root, 'reset']);

  if (stagedDiffPath && (await Bun.file(stagedDiffPath).exists())) {
    const check = await execSafe([
      'git',
      '-C',
      root,
      'apply',
      '--check',
      '--cached',
      stagedDiffPath,
    ]);

    if (check.exitCode !== 0) {
      logger.warn(
        'Context changed during rebase. Your staged changes are now unstaged to prevent corruption',
      );
      logger.warn(`Original staged files: ${originalStagedFiles}`);
      logger.info('You may need to manually re-stage files using: git add <file>');
      return;
    }

    const apply = await execSafe(['git', '-C', root, 'apply', '--cached', stagedDiffPath]);
    if (apply.exitCode === 0) {
      logger.success('Restored staged changes to index');
      return;
    }

    logger.warn('Could not apply staged patch despite check passing - attempting fallback');
    await restageFiles(root, originalStagedFiles);
    return;
  }

  logger.warn('Staged diff file not found, using fallback restoration');
  await restageFiles(root, originalStagedFiles);
}

async function restageFiles(root: string, originalStagedFiles: string): Promise<void> {
  await Promise.all(
    originalStagedFiles
      .split('\n')
      .filter(Boolean)
      .map((file) => execSafe(['git', '-C', root, 'add', file])),
  );
  logger.warn('Restored staging by re-adding files (partial staging may be lost)');
}

export async function removeDiffFiles(
  stagedDiffPath: string,
  unstagedDiffPath: string,
): Promise<void> {
  if (stagedDiffPath && (await Bun.file(stagedDiffPath).exists()))
    await $`rm -f ${stagedDiffPath}`.quiet();
  if (unstagedDiffPath && (await Bun.file(unstagedDiffPath).exists()))
    await $`rm -f ${unstagedDiffPath}`.quiet();
}
