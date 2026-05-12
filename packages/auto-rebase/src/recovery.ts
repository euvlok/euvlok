import { logger } from '@euvlok/core';
import { join } from 'pathe';
import { JJ_DIR } from './constants';
import { checkoutOriginalBranch, exportJjWorkingCopy, logPersistentJj } from './jj-git';
import { removeSavedDiffFiles, restoreGitIndexFromBackup } from './staging';
import type { RebaseState } from './state';
import { loadState, removeState } from './state';

export async function recoverInterruptedRebase(root: string): Promise<boolean> {
  const state = await loadState(root);
  if (!state) return true;

  logger.warn('Detected interrupted auto-rebase state. Attempting recovery...');

  if (await hasJjStore(root)) await recoverJjState(root, state);

  await removeSavedDiffFiles(state.stagedDiffPath, state.unstagedDiffPath);

  await removeState(root);
  logger.success('Recovery completed. You can now run the script again');
  return true;
}

function hasJjStore(root: string): Promise<boolean> {
  return Bun.file(join(root, JJ_DIR, 'repo', 'store', 'type')).exists();
}

async function recoverJjState(root: string, state: RebaseState): Promise<void> {
  logger.info('Found .jj directory from interrupted run');
  logger.info('Exporting jj working copy to git...');

  await checkoutOriginalBranch(root, state.originalBranch);
  if (await exportJjWorkingCopy(root)) {
    logger.success('Exported jj working copy to git');
  } else {
    logger.warn('Failed to export jj working copy during recovery');
  }
  await restoreOriginalStaging(root, state);
  logPersistentJj(state.jjWasPresent);
}

async function restoreOriginalStaging(root: string, state: RebaseState): Promise<void> {
  if (!state.originalHadStaged || !state.originalStagedFiles) return;
  await restoreGitIndexFromBackup(root, state.stagedDiffPath, state.originalStagedFiles);
}
