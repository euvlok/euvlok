import { logger } from '@euvlok/shared';
import { simpleGit } from 'simple-git';

export async function restoreStaging(
  root: string,
  stagedDiffPath: string,
  originalStagedFiles: string,
): Promise<void> {
  logger.info('Restoring original staging state...');
  const git = simpleGit(root);
  await git.reset();

  if (stagedDiffPath && (await Bun.file(stagedDiffPath).exists())) {
    const check = await git
      .raw(['apply', '--check', '--cached', stagedDiffPath])
      .then(() => true)
      .catch(() => false);

    if (!check) {
      logger.warn(
        'Context changed during rebase. Your staged changes are now unstaged to prevent corruption',
      );
      logger.warn(`Original staged files: ${originalStagedFiles}`);
      logger.info('You may need to manually re-stage files using: git add <file>');
      return;
    }

    const apply = await git
      .raw(['apply', '--cached', stagedDiffPath])
      .then(() => true)
      .catch(() => false);
    if (apply) {
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
  const git = simpleGit(root);
  const files = originalStagedFiles.split('\n').filter(Boolean);
  if (files.length > 0) await git.add(files);
  logger.warn('Restored staging by re-adding files (partial staging may be lost)');
}

export async function removeDiffFiles(
  stagedDiffPath: string,
  unstagedDiffPath: string,
): Promise<void> {
  if (stagedDiffPath && (await Bun.file(stagedDiffPath).exists()))
    await Bun.file(stagedDiffPath)
      .delete()
      .catch(() => undefined);
  if (unstagedDiffPath && (await Bun.file(unstagedDiffPath).exists()))
    await Bun.file(unstagedDiffPath)
      .delete()
      .catch(() => undefined);
}
