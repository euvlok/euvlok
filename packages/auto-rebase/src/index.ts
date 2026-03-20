import { defineCommand, runMain } from 'citty';
import { logger, execSafe, findRepoRoot, isGitRepo, isEuvlokRepo } from '@euvlok/shared';
import { createContext } from './context';
import { getOriginalBranch, checkGitLocks, fetchLatest } from './git';
import { setupJj, cleanupJj } from './jj';
import { createBackup } from './backup';
import { recoverFromInterruptedState } from './recovery';
import { getRemoteBookmark, checkLocalChanges, checkRemoteChanges } from './checks';
import { checkRebaseSafety, performRebase } from './rebase';
import { cleanupOnError } from './cleanup';

const main = defineCommand({
  meta: {
    name: 'auto-rebase',
    description:
      'Fetch the latest changes from remote and automatically rebase local changes on top of the latest remote if there are no conflicts',
  },
  args: {
    branch: {
      type: 'string',
      alias: 'b',
      description: 'Specify the branch to work on (default: current branch)',
    },
    'dry-run': {
      type: 'boolean',
      description: 'Show what would be done without actually rebasing',
      default: false,
    },
    'no-auto-rebase': {
      type: 'boolean',
      description: "Only check rebase safety, don't automatically rebase",
      default: false,
    },
    'backup-dir': {
      type: 'string',
      description: `Directory to store backup bundle (default: system temp dir)`,
      default: Bun.env.TMPDIR,
    },
  },
  async run({ args }) {
    const dryRun = args['dry-run'];
    const autoRebase = !args['no-auto-rebase'];
    const backupDir = args['backup-dir'] || Bun.env.TMPDIR || '/tmp';

    const root = await findRepoRoot();
    if (!root) {
      logger.error('Could not find repository root');
      process.exit(1);
    }

    if (!(await isGitRepo(root))) {
      logger.error('Not a git repository');
      process.exit(1);
    }

    logger.info(`Repository root: ${root}`);

    const recovered = await recoverFromInterruptedState(root);
    if (!recovered) {
      logger.error('Recovery failed. Please manually clean up:');
      logger.error("  1. Check for .jj directory and remove if you didn't create it");
      logger.error('  2. Remove .auto-rebase-state file if it exists');
      logger.error(`  3. Restore from backup if needed: ${backupDir}`);
      process.exit(1);
    }

    if (!(await isEuvlokRepo(root))) {
      logger.error('This is not an euvlok repository (missing .euvlok file)');
      logger.info('This script is designed to work only with the euvlok repository');
      process.exit(1);
    }

    const ctx = createContext(root, dryRun, autoRebase, backupDir);
    ctx.originalBranch = args.branch ?? (await getOriginalBranch(root));
    logger.info(`Original branch: ${ctx.originalBranch}`);

    await checkGitLocks(root);

    process.on('SIGINT', async () => {
      await cleanupOnError(ctx);
      process.exit(1);
    });
    process.on('SIGTERM', async () => {
      await cleanupOnError(ctx);
      process.exit(1);
    });

    try {
      ctx.backupFile = await createBackup(ctx);
      await setupJj(ctx);

      try {
        await fetchLatest(ctx);
      } catch (e) {
        await cleanupJj(ctx);
        throw e;
      }

      const local = await checkLocalChanges(root);
      const remote = await checkRemoteChanges(root);

      if (!local && !remote) {
        logger.info('No local or remote changes detected. Nothing to do');
        await cleanupJj(ctx);
        return;
      }

      if (!local && remote) {
        logger.info('Only remote changes detected. Updating to latest remote...');
        const target = await getRemoteBookmark(root);

        const result = await execSafe(['jj', 'rebase', '-b', '@', '-d', target], {
          cwd: root,
        });
        if (!dryRun) {
          if (result.exitCode !== 0) logger.warn('Rebase failed');
        }
        if (dryRun) {
          if (result.exitCode === 0) {
            logger.success('  [DRY RUN] Rebase would succeed');
          }
          if (result.exitCode !== 0) {
            logger.warn('  [DRY RUN] Rebase would fail');
          }
          await execSafe(['jj', 'undo'], { cwd: root });
        }

        await cleanupJj(ctx);
        return;
      }

      if (local && !remote) {
        logger.info('Only local changes detected. No rebase needed');
        await cleanupJj(ctx);
        return;
      }

      logger.info('Both local and remote changes detected. Checking rebase safety...');

      const safety = await checkRebaseSafety(ctx);

      if (!safety.safe) {
        logger.warn('Rebase may have conflicts. Not automatically rebasing');
        logger.info('Please resolve conflicts manually using standard Git commands:');
        logger.info('  git pull');
        logger.info(`Backup available at: ${ctx.backupFile}`);
      }

      if (safety.safe && autoRebase) {
        if (safety.rebaseAlreadyApplied) {
          logger.info('Rebase already completed during safety check (optimization)');
          logger.success('Successfully rebased local changes onto latest remote!');
        }
        if (!safety.rebaseAlreadyApplied) {
          logger.info('Rebase is safe. Automatically rebasing...');
          try {
            await performRebase(ctx);
            logger.success('Successfully rebased local changes onto latest remote!');
          } catch {
            await cleanupJj(ctx);
            process.exit(1);
          }
        }
      }

      if (safety.safe && !autoRebase) {
        if (safety.rebaseAlreadyApplied) {
          logger.info('Undoing test rebase (--no-auto-rebase is set)');
          await execSafe(['jj', 'undo'], { cwd: root });
        }
        logger.info('Rebase would be safe, but --no-auto-rebase is set. Skipping rebase');
      }

      await cleanupJj(ctx);

      logger.success('Operation completed!');
      if (dryRun) {
        logger.info('This was a dry run - no changes were made');
      }
      if (ctx.backupFile) {
        logger.info(`Backup saved at: ${ctx.backupFile}`);
      }
    } catch (e: unknown) {
      await cleanupOnError(ctx);
      logger.error(e instanceof Error ? e.message : String(e));
      process.exit(1);
    }
  },
});

runMain(main);
