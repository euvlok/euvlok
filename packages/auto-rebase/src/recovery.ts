import { execSafe, logger } from '@euvlok/shared';
import { join } from 'pathe';
import { simpleGit } from 'simple-git';
import { DETACHED_HEAD, JJ_DIR } from './constants';
import { removeDiffFiles, restoreStaging } from './staging';
import type { RebaseState } from './state';
import { loadState, removeState } from './state';

export async function recoverFromInterruptedState(root: string): Promise<boolean> {
  const state = await loadState(root);
  if (!state) return true;

  logger.warn('Detected interrupted auto-rebase state. Attempting recovery...');

  if (await hasJjStore(root)) await recoverJjState(root, state);

  await removeDiffFiles(state.stagedDiffPath, state.unstagedDiffPath);

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
  await exportJjWorkingCopy(root);
  await restoreOriginalStaging(root, state);
  logPersistentJj(state);
}

async function checkoutOriginalBranch(root: string, branch: string): Promise<void> {
  if (branch === DETACHED_HEAD) return;
  await simpleGit(root).checkout(branch);
}

async function exportJjWorkingCopy(root: string): Promise<void> {
  const result = await execSafe(['jj', 'git', 'export'], { cwd: root });
  if (result.exitCode === 0) {
    logger.success('Exported jj working copy to git');
    return;
  }

  logger.warn('Failed to export jj working copy during recovery');
}

async function restoreOriginalStaging(root: string, state: RebaseState): Promise<void> {
  if (!state.originalHadStaged || !state.originalStagedFiles) return;
  await restoreStaging(root, state.stagedDiffPath, state.originalStagedFiles);
}

function logPersistentJj(state: RebaseState): void {
  if (state.jjWasPresent) return;
  logger.info('Keeping .jj directory for future runs (persistent ephemerality)');
}
