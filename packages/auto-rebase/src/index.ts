import { findRepoRoot, isGitRepo, logger, runCommandResult } from '@euvlok/core';
import { buildApplication, buildCommand, run } from '@stricli/core';
import { createRebaseBackup } from './backup';
import { getRemoteBookmark, hasLocalChanges, hasRemoteChanges } from './checks';
import { cleanupRebaseAfterError } from './cleanup';
import { createRebaseContext, type RebaseContext } from './context';
import { assertNoGitLocks, fetchLatestRemoteState, getOriginalBranch } from './git';
import { cleanupJj, setupJj } from './jj';
import { checkRebaseSafety, performRebase } from './rebase';
import { recoverInterruptedRebase } from './recovery';

type AutoRebaseFlags = {
  branch?: string;
  dryRun: boolean;
  autoRebase: boolean;
  backupDir: string;
};

type ChangeState = 'none' | 'remote-only' | 'local-only' | 'local-and-remote';

async function exitWithError(message: string): Promise<never> {
  logger.error(message);
  process.exit(1);
}

async function requireRepositoryRoot(): Promise<string> {
  const root = await findRepoRoot();
  if (!root) return exitWithError('Could not find repository root');
  if (!(await isGitRepo(root))) await exitWithError('Not a git repository');

  logger.info(`Repository root: ${root}`);
  return root;
}

async function recoverRepository(root: string, backupDir: string): Promise<void> {
  const recovered = await recoverInterruptedRebase(root);
  if (recovered) return;

  logger.error('Recovery failed. Please manually clean up:');
  logger.error("  1. Check for .jj directory and remove if you didn't create it");
  logger.error('  2. Remove .auto-rebase-state file if it exists');
  logger.error(`  3. Restore from backup if needed: ${backupDir}`);
  process.exit(1);
}

async function requireEuvlokRepository(root: string): Promise<void> {
  if (await isEuvlokRepo(root)) return;

  logger.error('This is not an euvlok repository (missing .euvlok file)');
  logger.info('This script is designed to work only with the euvlok repository');
  process.exit(1);
}

async function isEuvlokRepo(dir: string): Promise<boolean> {
  return Bun.file(`${dir}/.euvlok`).exists();
}

function registerCleanupSignals(ctx: RebaseContext): void {
  const cleanupAndExit = async () => {
    await cleanupRebaseAfterError(ctx);
    process.exit(1);
  };

  process.on('SIGINT', cleanupAndExit);
  process.on('SIGTERM', cleanupAndExit);
}

async function fetchLatestWithCleanup(ctx: RebaseContext): Promise<void> {
  await fetchLatestRemoteState(ctx).catch(async (e) => {
    await cleanupJj(ctx);
    throw e;
  });
}

async function handleRemoteOnlyChanges(ctx: RebaseContext): Promise<void> {
  logger.info('Only remote changes detected. Updating to latest remote...');
  const target = await getRemoteBookmark(ctx.repoRoot);

  const result = await runCommandResult(['jj', 'rebase', '-b', '@', '-d', target], {
    cwd: ctx.repoRoot,
  });

  if (!ctx.dryRun && result.exitCode !== 0) logger.warn('Rebase failed');

  if (ctx.dryRun) {
    if (result.exitCode === 0) logger.success('  [DRY RUN] Rebase would succeed');
    if (result.exitCode !== 0) logger.warn('  [DRY RUN] Rebase would fail');
    await runCommandResult(['jj', 'undo'], { cwd: ctx.repoRoot });
  }

  await cleanupJj(ctx);
}

function changeState(local: boolean, remote: boolean): ChangeState {
  if (local && remote) return 'local-and-remote';
  if (local) return 'local-only';
  if (remote) return 'remote-only';
  return 'none';
}

async function handleChangeSet(ctx: RebaseContext): Promise<boolean> {
  const local = await hasLocalChanges(ctx.repoRoot);
  const remote = await hasRemoteChanges(ctx.repoRoot);

  switch (changeState(local, remote)) {
    case 'none':
      logger.info('No local or remote changes detected. Nothing to do');
      await cleanupJj(ctx);
      return true;
    case 'remote-only':
      await handleRemoteOnlyChanges(ctx);
      return true;
    case 'local-only':
      logger.info('Only local changes detected. No rebase needed');
      await cleanupJj(ctx);
      return true;
    case 'local-and-remote':
      return false;
  }
}

async function handleUnsafeRebase(ctx: RebaseContext): Promise<void> {
  logger.warn('Rebase may have conflicts. Not automatically rebasing');
  logger.info('Please resolve conflicts manually using standard Git commands:');
  logger.info('  git pull');
  logger.info(`Backup available at: ${ctx.backupFile}`);
}

async function handleSafeAutoRebase(
  ctx: RebaseContext,
  rebaseAlreadyApplied: boolean,
): Promise<void> {
  if (rebaseAlreadyApplied) {
    logger.info('Rebase already completed during safety check (optimization)');
    logger.success('Successfully rebased local changes onto latest remote!');
    return;
  }

  logger.info('Rebase is safe. Automatically rebasing...');
  await performRebase(ctx).catch(async () => {
    await cleanupJj(ctx);
    process.exit(1);
  });
  logger.success('Successfully rebased local changes onto latest remote!');
}

async function handleSafeManualRebase(
  ctx: RebaseContext,
  rebaseAlreadyApplied: boolean,
): Promise<void> {
  if (rebaseAlreadyApplied) {
    logger.info('Undoing test rebase (--no-auto-rebase is set)');
    await runCommandResult(['jj', 'undo'], { cwd: ctx.repoRoot });
  }

  logger.info('Rebase would be safe, but --no-auto-rebase is set. Skipping rebase');
}

async function handleLocalAndRemoteChanges(ctx: RebaseContext): Promise<void> {
  logger.info('Both local and remote changes detected. Checking rebase safety...');

  const safety = await checkRebaseSafety(ctx);

  if (!safety.safe) await handleUnsafeRebase(ctx);
  if (safety.safe && ctx.autoRebase) {
    await handleSafeAutoRebase(ctx, safety.rebaseAlreadyApplied);
  }
  if (safety.safe && !ctx.autoRebase) {
    await handleSafeManualRebase(ctx, safety.rebaseAlreadyApplied);
  }

  await cleanupJj(ctx);
}

function logCompletion(ctx: RebaseContext): void {
  logger.success('Operation completed!');
  if (ctx.dryRun) logger.info('This was a dry run - no changes were made');
  if (ctx.backupFile) logger.info(`Backup saved at: ${ctx.backupFile}`);
}

async function runAutoRebase(args: AutoRebaseFlags): Promise<void> {
  const root = await requireRepositoryRoot();
  await recoverRepository(root, args.backupDir);
  await requireEuvlokRepository(root);

  const ctx = createRebaseContext(root, args.dryRun, args.autoRebase, args.backupDir);
  ctx.originalBranch = args.branch ?? (await getOriginalBranch(root));
  logger.info(`Original branch: ${ctx.originalBranch}`);

  await assertNoGitLocks(root);
  registerCleanupSignals(ctx);

  try {
    ctx.backupFile = await createRebaseBackup(ctx);
    await setupJj(ctx);
    await fetchLatestWithCleanup(ctx);

    const handled = await handleChangeSet(ctx);
    if (!handled) await handleLocalAndRemoteChanges(ctx);

    logCompletion(ctx);
  } catch (e: unknown) {
    await cleanupRebaseAfterError(ctx);
    logger.error(e instanceof Error ? e.message : String(e));
    process.exit(1);
  }
}

const command = buildCommand<AutoRebaseFlags>({
  docs: {
    brief: 'Fetch remote changes and rebase local work when it is safe',
    fullDescription:
      'Fetches the latest changes from remote and automatically rebases local changes on top of the latest remote when there are no conflicts.',
  },
  parameters: {
    flags: {
      branch: {
        kind: 'parsed',
        parse: String,
        brief: 'Branch to work on. Defaults to the current branch.',
        optional: true,
      },
      dryRun: {
        kind: 'boolean',
        brief: 'Show what would be done without actually rebasing.',
        default: false,
      },
      autoRebase: {
        kind: 'boolean',
        brief: 'Automatically rebase when the safety check passes.',
        default: true,
      },
      backupDir: {
        kind: 'parsed',
        parse: String,
        brief: 'Directory to store the backup bundle.',
        default: Bun.env.TMPDIR || '/tmp',
      },
    },
    aliases: {
      b: 'branch',
    },
  },
  async func(args) {
    await runAutoRebase(args);
  },
});

const app = buildApplication(command, {
  name: 'auto-rebase',
  scanner: {
    caseStyle: 'allow-kebab-for-camel',
  },
});

await run(app, Bun.argv.slice(2), { process });
