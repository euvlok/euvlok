import { logger, execSafe } from '@euvlok/shared';
import { join } from 'pathe';
import type { RebaseContext } from './context';
import { GIT_DIR, DEFAULT_REMOTE, COMMON_BRANCH_NAMES } from './constants';

export async function getOriginalBranch(root: string): Promise<string> {
  const result = await execSafe(['git', '-C', root, 'symbolic-ref', '--short', 'HEAD']);
  if (result.exitCode === 0 && result.stdout) return result.stdout;
  const abbrev = await execSafe(['git', '-C', root, 'rev-parse', '--abbrev-ref', 'HEAD']);
  return abbrev.stdout || 'HEAD';
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
  const remote = await execSafe([
    'git',
    '-C',
    ctx.repoRoot,
    'remote',
    'get-url',
    DEFAULT_REMOTE,
  ]);
  if (remote.exitCode !== 0) {
    throw new Error(`No '${DEFAULT_REMOTE}' remote configured. Cannot fetch changes`);
  }
  const result = await execSafe(['git', '-C', ctx.repoRoot, 'fetch', DEFAULT_REMOTE]);
  if (result.exitCode !== 0) {
    throw new Error(`Failed to fetch from ${DEFAULT_REMOTE}`);
  }
  for (const bookmark of COMMON_BRANCH_NAMES) {
    const ref = await execSafe([
      'git',
      '-C',
      ctx.repoRoot,
      'show-ref',
      '--verify',
      '--quiet',
      `refs/remotes/${DEFAULT_REMOTE}/${bookmark}`,
    ]);
    if (ref.exitCode === 0) {
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
