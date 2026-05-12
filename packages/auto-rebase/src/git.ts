import { logger, runCommandResult } from '@euvlok/core';
import { join } from 'pathe';
import { simpleGit } from 'simple-git';
import { COMMON_BRANCH_NAMES, DEFAULT_REMOTE, GIT_DIR } from './constants';
import type { RebaseContext } from './context';

export async function getOriginalBranch(root: string): Promise<string> {
  const git = simpleGit(root);
  const branch = await git.branchLocal();
  return branch.detached ? 'HEAD' : branch.current || 'HEAD';
}

export async function assertNoGitLocks(root: string): Promise<void> {
  const idx = join(root, GIT_DIR, 'index.lock');
  const head = join(root, GIT_DIR, 'HEAD.lock');
  if (!(await Bun.file(idx).exists()) && !(await Bun.file(head).exists())) return;
  logger.warn('Git lock file detected. Waiting up to 5 seconds...');

  const locksCleared = await Array.from({ length: 10 }).reduce(async (previous) => {
    if (await previous) return true;
    await Bun.sleep(500);
    return !(await Bun.file(idx).exists()) && !(await Bun.file(head).exists());
  }, Promise.resolve(false));

  if (!locksCleared) {
    throw new Error(
      'Git locks still present after waiting. Please manually resolve Git locks before running this script',
    );
  }
}

export async function fetchLatestRemoteState(ctx: RebaseContext): Promise<void> {
  logger.info('Fetching latest changes from remote...');
  if (ctx.dryRun) {
    logger.info(`  [DRY RUN] Would run: git fetch ${DEFAULT_REMOTE} && jj git fetch --remote ${DEFAULT_REMOTE}`);
    return;
  }
  const git = simpleGit(ctx.repoRoot);
  await fetchGitRemote(git);
  await trackRemoteBookmark(ctx.repoRoot, git);
  await fetchJjRemote(ctx.repoRoot);
  logger.success('Fetched latest changes from git remote');
}

async function fetchGitRemote(git: ReturnType<typeof simpleGit>): Promise<void> {
  const remotes = await git.getRemotes(true);
  if (!remotes.some((remote) => remote.name === DEFAULT_REMOTE)) {
    throw new Error(`No '${DEFAULT_REMOTE}' remote configured. Cannot fetch changes`);
  }
  await git.fetch(DEFAULT_REMOTE).catch(() => {
    throw new Error(`Failed to fetch from ${DEFAULT_REMOTE}`);
  });
}

async function remoteBookmarkExists(git: ReturnType<typeof simpleGit>, bookmark: string): Promise<boolean> {
  return git
    .raw(['show-ref', '--verify', '--quiet', `refs/remotes/${DEFAULT_REMOTE}/${bookmark}`])
    .then(() => true)
    .catch(() => false);
}

async function firstRemoteBookmark(git: ReturnType<typeof simpleGit>): Promise<string | undefined> {
  const results = await Promise.all(
    COMMON_BRANCH_NAMES.map(async (bookmark) => ({
      bookmark,
      refFound: await remoteBookmarkExists(git, bookmark),
    })),
  );
  return results.find((result) => result.refFound)?.bookmark;
}

async function trackRemoteBookmark(root: string, git: ReturnType<typeof simpleGit>): Promise<void> {
  const bookmark = await firstRemoteBookmark(git);

  if (bookmark) {
    await runCommandResult(['jj', 'bookmark', 'track', `${bookmark}@${DEFAULT_REMOTE}`], {
      cwd: root,
    });
  }
}

async function fetchJjRemote(root: string): Promise<void> {
  const jj = await runCommandResult(['jj', 'git', 'fetch', '--remote', DEFAULT_REMOTE], {
    cwd: root,
  });
  if (jj.exitCode !== 0) {
    throw new Error('Failed to fetch from git remote');
  }
}
