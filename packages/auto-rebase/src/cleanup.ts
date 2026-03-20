import { logger } from '@euvlok/shared';
import type { RebaseContext } from './context';
import { cleanupJj } from './jj';
import { removeDiffFiles } from './staging';

export async function cleanupOnError(ctx: RebaseContext): Promise<void> {
  logger.error('Script failed. Attempting cleanup...');

  await removeDiffFiles(ctx.stagedDiffPath, ctx.unstagedDiffPath);

  await cleanupJj(ctx);
  logger.info(`Backup available at: ${ctx.backupFile}`);
  logger.info(`To restore: git clone ${ctx.backupFile} <destination>`);
  logger.info('If cleanup failed, run the script again - it will attempt recovery automatically');
}
