import { logger, execSafe } from '@euvlok/shared';
import { join } from 'pathe';
import { JJ_DIR, DETACHED_HEAD } from './constants';
import { loadState, removeState } from './state';
import { restoreStaging, removeDiffFiles } from './staging';

export async function recoverFromInterruptedState(root: string): Promise<boolean> {
  const state = await loadState(root);
  if (!state) return true;

  logger.warn('Detected interrupted auto-rebase state. Attempting recovery...');

  if (await Bun.file(join(root, JJ_DIR, 'repo', 'store', 'type')).exists()) {
    logger.info('Found .jj directory from interrupted run');
    logger.info('Exporting jj working copy to git...');

    if (state.originalBranch !== DETACHED_HEAD) {
      await execSafe(['git', '-C', root, 'checkout', state.originalBranch]);
    }

    const result = await execSafe(['jj', 'git', 'export'], { cwd: root });
    const msg = result.exitCode === 0
      ? 'Exported jj working copy to git'
      : 'Failed to export jj working copy during recovery';
    result.exitCode === 0 ? logger.success(msg) : logger.warn(msg);

    if (state.originalHadStaged && state.originalStagedFiles) {
      await restoreStaging(root, state.stagedDiffPath, state.originalStagedFiles);
    }

    if (!state.jjWasPresent) {
      logger.info('Keeping .jj directory for future runs (persistent ephemerality)');
    }
  }

  await removeDiffFiles(state.stagedDiffPath, state.unstagedDiffPath);

  await removeState(root);
  logger.success('Recovery completed. You can now run the script again');
  return true;
}
