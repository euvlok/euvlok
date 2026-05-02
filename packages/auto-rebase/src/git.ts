import { execSafe, logger } from '@euvlok/shared';
import { join } from 'pathe';
import { simpleGit } from 'simple-git';
import { COMMON_BRANCH_NAMES, DEFAULT_REMOTE, GIT_DIR } from './constants';
import type { RebaseContext } from './context';

export async function getOriginalBranch(root: string): Promise<string> {
  const git = simpleGit(root);
  const branch = await git.branchLocal();
  return branch.detached ? 'HEAD' : branch.current || 'HEAD';
}

export async function checkGitLocks(root: string): Promise<void> {
  const idx = join(root, GIT_DIR, 'index.lock');
  const head = join(root, GIT_DIR, 'HEAD.lock');
  if (!(await Bun.file(idx).exists()) && !(await Bun.file(head).exists())) return;
  logger.warn('Git lock file detected. Waiting up to 5 seconds...');
  for (let i = 0; i < 10; i++) {
    if (!(await Bun.file(idx).exists()) && !(await Bun.file(head).exists())) return;
    await Bun.sleep(500);
  }
  if ((await Bun.file(idx).exists()) || (await Bun.file(head).exists())) {
    throw new Error(
      'Git locks still present after waiting. Please manually resolve Git locks before running this script',
    );
  }
}

export async function fetchLatest(ctx: RebaseContext): Promise<void> {
  logger.info('Fetching latest changes from remote...');
  if (ctx.dryRun) {
    logger.info(
      `  [DRY RUN] Would run: git fetch ${DEFAULT_REMOTE} && jj git fetch --remote ${DEFAULT_REMOTE}`,
    );
    return;
  }
  const git = simpleGit(ctx.repoRoot);
  const remotes = await git.getRemotes(true);
  if (!remotes.some((remote) => remote.name === DEFAULT_REMOTE)) {
    throw new Error(`No '${DEFAULT_REMOTE}' remote configured. Cannot fetch changes`);
  }
  try {
    await git.fetch(DEFAULT_REMOTE);
  } catch {
    throw new Error(`Failed to fetch from ${DEFAULT_REMOTE}`);
  }
  for (const bookmark of COMMON_BRANCH_NAMES) {
    const refFound = await git
      .raw(['show-ref', '--verify', '--quiet', `refs/remotes/${DEFAULT_REMOTE}/${bookmark}`])
      .then(() => true)
      .catch(() => false);
    if (refFound) {
      await execSafe(['jj', 'bookmark', 'track', `${bookmark}@${DEFAULT_REMOTE}`], {
        cwd: ctx.repoRoot,
      });
      break;
    }
  }
  const jj = await execSafe(['jj', 'git', 'fetch', '--remote', DEFAULT_REMOTE], {
    cwd: ctx.repoRoot,
  });
  if (jj.exitCode !== 0) {
    throw new Error('Failed to fetch from git remote');
  }
  logger.success('Fetched latest changes from git remote');
}
