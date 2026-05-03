import { logger } from '@euvlok/core';
import type { RebaseContext } from './context';
import { cleanupJj } from './jj';
import { removeSavedDiffFiles } from './staging';

export async function cleanupRebaseAfterError(ctx: RebaseContext): Promise<void> {
  logger.error('Script failed. Attempting cleanup...');

  await removeSavedDiffFiles(ctx.stagedDiffPath, ctx.unstagedDiffPath);

  await cleanupJj(ctx);
  logger.info(`Backup available at: ${ctx.backupFile}`);
  logger.info(`To restore: git clone ${ctx.backupFile} <destination>`);
  logger.info('If cleanup failed, run the script again - it will attempt recovery automatically');
}
