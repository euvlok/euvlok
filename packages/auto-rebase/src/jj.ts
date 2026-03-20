import { $ } from 'bun';
import { logger, execSafe, isGitRepo } from '@euvlok/shared';
import { join } from 'pathe';
import type { RebaseContext } from './context';
import { JJ_DIR, EUVLOK_TMP_DIR, DEFAULT_REMOTE, DETACHED_HEAD } from './constants';
import { saveState, removeState } from './state';
import { restoreStaging, removeDiffFiles } from './staging';

function exists(root: string): Promise<boolean> {
  return Bun.file(join(root, JJ_DIR, 'repo', 'store', 'type')).exists();
}

export async function checkJjPresent(root: string): Promise<boolean> {
  if (!(await exists(root))) return false;
  const which = await execSafe(['which', 'jj']);
  if (which.exitCode !== 0) return false;
  const log = await execSafe(['jj', 'log', '-r', '@', '--limit', '1'], {
    cwd: root,
  });
  return log.exitCode === 0;
}

export async function persistState(ctx: RebaseContext): Promise<void> {
  await saveState(ctx.repoRoot, {
    originalBranch: ctx.originalBranch || DETACHED_HEAD,
    originalHadStaged: ctx.originalHadStaged,
    originalStagedFiles: ctx.originalStagedFiles,
    stagedDiffPath: ctx.stagedDiffPath,
    unstagedDiffPath: ctx.unstagedDiffPath,
    jjWasPresent: ctx.jjWasPresent,
    timestamp: Math.floor(Date.now() / 1000),
  });
}

export async function setupJj(ctx: RebaseContext): Promise<void> {
  const root = ctx.repoRoot;
  const branch = ctx.originalBranch;

  if (await exists(root)) {
    if (await checkJjPresent(root)) {
      ctx.jjWasPresent = true;
      logger.info('Jujutsu repository already present');
      logger.info('Syncing jj repository with Git changes...');
      await execSafe(['jj', 'git', 'fetch', '--remote', DEFAULT_REMOTE], {
        cwd: root,
      });
      if (branch !== DETACHED_HEAD) {
        await execSafe(['jj', 'bookmark', 'set', branch, '-r', '@'], {
          cwd: root,
        });
      }
      return;
    }
    logger.warn('Found invalid .jj directory, removing and reinitializing...');
    await $`rm -rf ${join(root, JJ_DIR)}`.quiet();
  }

  if (!(await isGitRepo(root))) {
    throw new Error('Not a git repository. Cannot initialize jujutsu');
  }

  logger.info('Initializing jujutsu for operations...');

  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Would run: jj git init --git-repo=. && jj bookmark set');
    return;
  }

  await $`mkdir -p ${join(root, EUVLOK_TMP_DIR)}`.quiet();
  const timestamp = Math.floor(Date.now() / 1000);

  const cached = await execSafe(['git', '-C', root, 'diff', '--cached', '--quiet']);
  if (cached.exitCode !== 0) {
    ctx.originalHadStaged = true;
    const staged = await execSafe([
      'git',
      '-C',
      root,
      'diff',
      '--cached',
      '--name-only',
    ]);
    ctx.originalStagedFiles = staged.stdout;

    ctx.stagedDiffPath = join(root, EUVLOK_TMP_DIR, `staged-${timestamp}.diff`);
    const diff = await execSafe(['git', '-C', root, 'diff', '--cached']);
    if (diff.exitCode === 0) {
      await Bun.write(ctx.stagedDiffPath, diff.stdout);
    }
    if (diff.exitCode !== 0) {
      logger.warn('Failed to capture staged diff');
      ctx.stagedDiffPath = '';
    }

    ctx.unstagedDiffPath = join(root, EUVLOK_TMP_DIR, `unstaged-${timestamp}.diff`);
    const unstaged = await execSafe(['git', '-C', root, 'diff']);
    if (unstaged.exitCode === 0) {
      await Bun.write(ctx.unstagedDiffPath, unstaged.stdout);
    }
    if (unstaged.exitCode !== 0) {
      logger.warn('Failed to capture unstaged diff');
      ctx.unstagedDiffPath = '';
    }
  }

  const init = await execSafe(['jj', 'git', 'init', `--git-repo=${root}`], {
    cwd: root,
  });
  if (init.exitCode !== 0) {
    throw new Error(`Failed to initialize jujutsu: ${init.stderr}`);
  }

  ctx.cleanupNeeded = true;
  await persistState(ctx);

  if (branch !== DETACHED_HEAD) {
    await execSafe(['jj', 'bookmark', 'set', branch, '-r', '@'], { cwd: root });
  }

  await persistState(ctx);
  logger.success('Jujutsu initialized');
}

export async function cleanupJj(ctx: RebaseContext): Promise<void> {
  const root = ctx.repoRoot;
  const branch = ctx.originalBranch;

  if (ctx.jjWasPresent) {
    if (branch !== DETACHED_HEAD) {
      await execSafe(['jj', 'bookmark', 'set', branch, '-r', '@'], {
        cwd: root,
      });
    }
    return;
  }

  if (!ctx.cleanupNeeded) return;

  logger.info('Cleaning up temporary jujutsu repository...');

  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Would export jj working copy to git (but not actually exporting)');
    return;
  }

  logger.info('Exporting jj working copy back to git...');

  if (branch !== DETACHED_HEAD) {
    await execSafe(['git', '-C', root, 'checkout', branch]);
  }

  const exported = await execSafe(['jj', 'git', 'export'], { cwd: root });
  if (exported.exitCode !== 0) {
    logger.warn('Failed to export jj working copy to git');
    return;
  }

  if (ctx.originalHadStaged && ctx.originalStagedFiles) {
    await restoreStaging(root, ctx.stagedDiffPath, ctx.originalStagedFiles);

    const current = await execSafe([
      'git',
      '-C',
      root,
      'diff',
      '--cached',
      '--name-only',
    ]);
    const now = current.stdout.split('\n').filter(Boolean).sort().join('\n');
    const expected = ctx.originalStagedFiles.split('\n').filter(Boolean).sort().join('\n');

    if (now !== expected) {
      logger.warn('Staging state restoration incomplete');
      logger.info(`Original staged: ${ctx.originalStagedFiles}`);
      logger.info(`Current staged: ${now || 'none'}`);
    }
    if (now === expected) {
      logger.success('Staging state restored correctly');
    }
  }

  if (!ctx.originalHadStaged || !ctx.originalStagedFiles) {
    const current = await execSafe([
      'git',
      '-C',
      root,
      'diff',
      '--cached',
      '--name-only',
    ]);
    if (current.stdout) {
      logger.warn(`Unexpected staged files after export: ${current.stdout}`);
      await execSafe(['git', '-C', root, 'reset']);
    }
    if (!current.stdout) {
      logger.success('Staging state preserved (no files staged)');
    }
  }

  logger.info('Restored git state from jj working copy');

  if ((await exists(root)) && !ctx.jjWasPresent) {
    logger.info('Keeping .jj directory for future runs (persistent ephemerality)');
  }

  await removeDiffFiles(ctx.stagedDiffPath, ctx.unstagedDiffPath);

  logger.success('Cleanup completed');
  await removeState(root);
}
