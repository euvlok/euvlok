import { execSafe, isGitRepo, listStagedFiles, logger } from '@euvlok/shared';
import { $ } from 'bun';
import { join } from 'pathe';
import { simpleGit } from 'simple-git';
import { DEFAULT_REMOTE, DETACHED_HEAD, EUVLOK_TMP_DIR, JJ_DIR } from './constants';
import type { RebaseContext } from './context';
import { removeDiffFiles, restoreStaging } from './staging';
import { removeState, saveState } from './state';

function exists(root: string): Promise<boolean> {
  return Bun.file(join(root, JJ_DIR, 'repo', 'store', 'type')).exists();
}

async function checkJjPresent(root: string): Promise<boolean> {
  if (!(await exists(root))) return false;
  const which = await execSafe(['which', 'jj']);
  if (which.exitCode !== 0) return false;
  const log = await execSafe(['jj', 'log', '-r', '@', '--limit', '1'], {
    cwd: root,
  });
  return log.exitCode === 0;
}

async function persistState(ctx: RebaseContext): Promise<void> {
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

async function setBookmark(root: string, branch: string): Promise<void> {
  if (branch === DETACHED_HEAD) return;
  await execSafe(['jj', 'bookmark', 'set', branch, '-r', '@'], { cwd: root });
}

async function syncExistingJj(ctx: RebaseContext): Promise<void> {
  ctx.jjWasPresent = true;
  logger.info('Jujutsu repository already present');
  logger.info('Syncing jj repository with Git changes...');
  await execSafe(['jj', 'git', 'fetch', '--remote', DEFAULT_REMOTE], {
    cwd: ctx.repoRoot,
  });
  await setBookmark(ctx.repoRoot, ctx.originalBranch);
}

async function removeInvalidJj(root: string): Promise<void> {
  logger.warn('Found invalid .jj directory, removing and reinitializing...');
  await $`rm -rf ${join(root, JJ_DIR)}`.quiet();
}

async function useExistingJjIfValid(ctx: RebaseContext): Promise<boolean> {
  if (!(await exists(ctx.repoRoot))) return false;
  if (!(await checkJjPresent(ctx.repoRoot))) {
    await removeInvalidJj(ctx.repoRoot);
    return false;
  }

  await syncExistingJj(ctx);
  return true;
}

async function captureDiff(
  git: ReturnType<typeof simpleGit>,
  path: string,
  args: string[],
): Promise<string> {
  return git
    .raw(args)
    .then(async (diff) => {
      await Bun.write(path, diff);
      return path;
    })
    .catch(() => {
      logger.warn(`Failed to capture ${args.includes('--cached') ? 'staged' : 'unstaged'} diff`);
      return '';
    });
}

async function captureOriginalStaging(ctx: RebaseContext): Promise<void> {
  await $`mkdir -p ${join(ctx.repoRoot, EUVLOK_TMP_DIR)}`.quiet();
  const timestamp = Math.floor(Date.now() / 1000);
  const git = simpleGit({ baseDir: ctx.repoRoot, trimmed: false });
  const cachedHasDiff = await git
    .raw(['diff', '--cached', '--quiet'])
    .then(() => false)
    .catch(() => true);

  if (!cachedHasDiff) return;

  ctx.originalHadStaged = true;
  ctx.originalStagedFiles = (await listStagedFiles(ctx.repoRoot)).join('\n');
  ctx.stagedDiffPath = await captureDiff(
    git,
    join(ctx.repoRoot, EUVLOK_TMP_DIR, `staged-${timestamp}.diff`),
    ['diff', '--cached'],
  );
  ctx.unstagedDiffPath = await captureDiff(
    git,
    join(ctx.repoRoot, EUVLOK_TMP_DIR, `unstaged-${timestamp}.diff`),
    ['diff'],
  );
}

async function initJj(ctx: RebaseContext): Promise<void> {
  const init = await execSafe(['jj', 'git', 'init', `--git-repo=${ctx.repoRoot}`], {
    cwd: ctx.repoRoot,
  });

  if (init.exitCode !== 0) {
    throw new Error(`Failed to initialize jujutsu: ${init.stderr}`);
  }

  ctx.cleanupNeeded = true;
  await persistState(ctx);
}

export async function setupJj(ctx: RebaseContext): Promise<void> {
  const root = ctx.repoRoot;

  if (await useExistingJjIfValid(ctx)) return;
  if (!(await isGitRepo(root))) throw new Error('Not a git repository. Cannot initialize jujutsu');

  logger.info('Initializing jujutsu for operations...');
  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Would run: jj git init --git-repo=. && jj bookmark set');
    return;
  }

  await captureOriginalStaging(ctx);
  await initJj(ctx);
  await setBookmark(root, ctx.originalBranch);
  await persistState(ctx);
  logger.success('Jujutsu initialized');
}

function normalizeFileList(files: string): string {
  return files.split('\n').filter(Boolean).sort().join('\n');
}

async function restoreOriginalStaging(ctx: RebaseContext): Promise<void> {
  await restoreStaging(ctx.repoRoot, ctx.stagedDiffPath, ctx.originalStagedFiles);

  const current = (await listStagedFiles(ctx.repoRoot)).join('\n');
  const now = normalizeFileList(current);
  const expected = normalizeFileList(ctx.originalStagedFiles);

  if (now !== expected) {
    logger.warn('Staging state restoration incomplete');
    logger.info(`Original staged: ${ctx.originalStagedFiles}`);
    logger.info(`Current staged: ${now || 'none'}`);
    return;
  }

  logger.success('Staging state restored correctly');
}

async function clearUnexpectedStaging(ctx: RebaseContext): Promise<void> {
  const git = simpleGit(ctx.repoRoot);
  const current = (await listStagedFiles(ctx.repoRoot)).join('\n');
  if (!current) {
    logger.success('Staging state preserved (no files staged)');
    return;
  }

  logger.warn(`Unexpected staged files after export: ${current}`);
  await git.reset();
}

async function restoreStagingState(ctx: RebaseContext): Promise<void> {
  if (ctx.originalHadStaged && ctx.originalStagedFiles) {
    await restoreOriginalStaging(ctx);
    return;
  }

  await clearUnexpectedStaging(ctx);
}

async function checkoutOriginalBranch(root: string, branch: string): Promise<void> {
  if (branch === DETACHED_HEAD) return;
  await simpleGit(root).checkout(branch);
}

async function exportJjWorkingCopy(root: string): Promise<boolean> {
  const exported = await execSafe(['jj', 'git', 'export'], { cwd: root });
  if (exported.exitCode === 0) return true;

  logger.warn('Failed to export jj working copy to git');
  return false;
}

async function logPersistentJj(root: string): Promise<void> {
  if (!(await exists(root))) return;
  logger.info('Keeping .jj directory for future runs (persistent ephemerality)');
}

export async function cleanupJj(ctx: RebaseContext): Promise<void> {
  const root = ctx.repoRoot;
  const branch = ctx.originalBranch;

  if (ctx.jjWasPresent) {
    await setBookmark(root, branch);
    return;
  }

  if (!ctx.cleanupNeeded) return;

  logger.info('Cleaning up temporary jujutsu repository...');

  if (ctx.dryRun) {
    logger.info('  [DRY RUN] Would export jj working copy to git (but not actually exporting)');
    return;
  }

  logger.info('Exporting jj working copy back to git...');

  await checkoutOriginalBranch(root, branch);
  if (!(await exportJjWorkingCopy(root))) return;

  await restoreStagingState(ctx);

  logger.info('Restored git state from jj working copy');
  await logPersistentJj(root);

  await removeDiffFiles(ctx.stagedDiffPath, ctx.unstagedDiffPath);

  logger.success('Cleanup completed');
  await removeState(root);
}
