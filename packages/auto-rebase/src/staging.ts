import { addGitPaths, logger } from '@euvlok/shared';
import { ResetMode, simpleGit } from 'simple-git';

export async function restoreStaging(
  root: string,
  stagedDiffPath: string,
  originalStagedFiles: string,
): Promise<void> {
  logger.info('Restoring original staging state...');
  const git = simpleGit(root);
  await git.reset(ResetMode.MIXED);

  if (stagedDiffPath && (await Bun.file(stagedDiffPath).exists())) {
    const check = await git
      .applyPatch(stagedDiffPath, ['--check', '--cached'])
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
      .applyPatch(stagedDiffPath, ['--cached'])
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
  const files = originalStagedFiles.split('\n').filter(Boolean);
  await addGitPaths(files, root);
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
