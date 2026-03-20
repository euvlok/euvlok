import { logger, execSafe } from '@euvlok/shared';
import {
  DEFAULT_REMOTE,
  COMMON_BRANCH_NAMES,
  JJ_TEMPLATE_COMMIT_ID,
  JJ_TEMPLATE_BOOKMARKS,
} from './constants';

// TODO: Cache result — each call makes up to 4 subprocess calls, and this is called 4+ times per run
export async function getRemoteBookmark(root: string): Promise<string> {
  for (const bookmark of COMMON_BRANCH_NAMES) {
    const result = await execSafe(
      ['jj', 'log', '-r', `${bookmark}@${DEFAULT_REMOTE}`, '--limit', '1'],
      { cwd: root },
    );
    if (result.exitCode === 0) return `${bookmark}@${DEFAULT_REMOTE}`;
  }

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
    const first = fallback.stdout.split('\n')[0]?.trim().split(/\s+/)[0];
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

  const lines = local.stdout.split('\n').filter((l) => l.trim().length > 0);
  if (lines.length > 0) {
    logger.info(`Found ${lines.length} local commit(s) ahead of remote`);
    return true;
  }

  return false;
}

export async function checkRemoteChanges(root: string): Promise<boolean> {
  const target = await getRemoteBookmark(root);
  const remote = await execSafe(
    ['jj', 'log', '-r', `@..${target}`, '--no-graph', '-T', JJ_TEMPLATE_COMMIT_ID],
    { cwd: root },
  );

  const lines = remote.stdout.split('\n').filter((l) => l.trim().length > 0);
  if (lines.length > 0) {
    logger.info(`Found ${lines.length} new commit(s) on remote`);
    return true;
  }

  return false;
}
