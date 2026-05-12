import { logger, runCommandResult } from '@euvlok/core';
import { simpleGit } from 'simple-git';
import { DETACHED_HEAD } from './constants';

export async function checkoutOriginalBranch(root: string, branch: string): Promise<void> {
  if (branch === DETACHED_HEAD) return;
  await simpleGit(root).checkout(branch);
}

export async function exportJjWorkingCopy(root: string): Promise<boolean> {
  const result = await runCommandResult(['jj', 'git', 'export'], { cwd: root });
  return result.exitCode === 0;
}

export function logPersistentJj(jjWasPresent: boolean): void {
  if (jjWasPresent) return;
  logger.info('Keeping .jj directory for future runs (persistent ephemerality)');
}
