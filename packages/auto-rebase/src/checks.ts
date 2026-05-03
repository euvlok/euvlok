import { execSafe, logger, nonEmptyLines } from '@euvlok/shared';
import {
  COMMON_BRANCH_NAMES,
  DEFAULT_REMOTE,
  JJ_TEMPLATE_BOOKMARKS,
  JJ_TEMPLATE_COMMIT_ID,
} from './constants';

// TODO: Cache result — each call makes up to 4 subprocess calls, and this is called 4+ times per run
export async function getRemoteBookmark(root: string): Promise<string> {
  const commonBookmark = await COMMON_BRANCH_NAMES.reduce(async (previous, bookmark) => {
    const found = await previous;
    if (found) return found;

    return (
      await execSafe(['jj', 'log', '-r', `${bookmark}@${DEFAULT_REMOTE}`, '--limit', '1'], {
        cwd: root,
      })
    ).exitCode === 0
      ? bookmark
      : null;
  }, Promise.resolve<string | null>(null));

  if (commonBookmark) return `${commonBookmark}@${DEFAULT_REMOTE}`;

  const fallback = await execSafe(
    [
      'jj',
      'log',
      '-r',
      `remote_bookmarks(remote="${DEFAULT_REMOTE}")`,
      '--template',
      JJ_TEMPLATE_BOOKMARKS,
      '--no-graph',
      '--limit',
      '1',
    ],
    { cwd: root },
  );

  if (fallback.stdout) {
    const first = nonEmptyLines(fallback.stdout)[0]?.split(/\s+/)[0];
    if (first) return first;
  }

  return 'remote_bookmarks()';
}

export async function checkLocalChanges(root: string): Promise<boolean> {
  const status = await execSafe(['jj', 'status'], { cwd: root });
  if (status.stdout.includes('Working copy changes:')) {
    logger.info('Found uncommitted changes in working directory');
    return true;
  }

  const target = await getRemoteBookmark(root);
  const local = await execSafe(
    ['jj', 'log', '-r', `${target}..@-`, '--no-graph', '-T', JJ_TEMPLATE_COMMIT_ID],
    { cwd: root },
  );

  return hasCommits(local.stdout, (count) => `Found ${count} local commit(s) ahead of remote`);
}

export async function checkRemoteChanges(root: string): Promise<boolean> {
  const target = await getRemoteBookmark(root);
  const remote = await execSafe(
    ['jj', 'log', '-r', `@..${target}`, '--no-graph', '-T', JJ_TEMPLATE_COMMIT_ID],
    { cwd: root },
  );

  return hasCommits(remote.stdout, (count) => `Found ${count} new commit(s) on remote`);
}

function hasCommits(stdout: string, message: (count: number) => string): boolean {
  const lines = nonEmptyLines(stdout);
  if (lines.length > 0) {
    logger.info(message(lines.length));
    return true;
  }

  return false;
}
