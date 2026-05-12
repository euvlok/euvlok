import { describe, expect, mock, test } from 'bun:test';
import { join } from 'pathe';
import { pushCommitToRemote, runRealCommandResult, silentLogger, useTempJjRepo } from './test-utils';

mock.module('@euvlok/core', () => ({
  runCommandResult: runRealCommandResult,
  logger: silentLogger,
}));

import { getRemoteBookmark, hasLocalChanges, hasRemoteChanges } from '../src/checks';

describe('getRemoteBookmark', () => {
  const repo = useTempJjRepo();

  test('returns master@origin for repo with master branch', async () => {
    expect(await getRemoteBookmark(repo.current().dir)).toBe('master@origin');
  });

  test('falls back to remote_bookmarks() when no common bookmarks exist', async () => {
    const current = repo.current();
    // Rename master to something uncommon on the remote
    await runRealCommandResult(['git', '-C', current.remoteDir, 'branch', '-m', 'master', 'uncommon-branch']);
    // Re-fetch so jj sees the new branch name
    await runRealCommandResult(['jj', 'git', 'fetch', '--remote', 'origin'], { cwd: current.dir });
    const result = await getRemoteBookmark(current.dir);
    expect(result).toBe('uncommon-branch@origin');
  });
});

describe('hasLocalChanges', () => {
  const repo = useTempJjRepo();

  test('returns false when clean and in sync with remote', async () => {
    expect(await hasLocalChanges(repo.current().dir)).toBe(false);
  });

  test('returns true when working copy has modifications', async () => {
    const current = repo.current();
    await Bun.write(join(current.dir, 'README'), 'modified\n');
    expect(await hasLocalChanges(current.dir)).toBe(true);
  });

  test('returns true when working copy has new files', async () => {
    const current = repo.current();
    await Bun.write(join(current.dir, 'new-file.txt'), 'new content\n');
    expect(await hasLocalChanges(current.dir)).toBe(true);
  });

  test('returns true when local commit ahead of remote', async () => {
    const current = repo.current();
    await Bun.write(join(current.dir, 'local.txt'), 'local\n');
    await runRealCommandResult(['jj', 'new', '-m', 'local commit'], { cwd: current.dir });
    expect(await hasLocalChanges(current.dir)).toBe(true);
  });
});

describe('hasRemoteChanges', () => {
  const repo = useTempJjRepo();

  test('returns false when remote is in sync', async () => {
    expect(await hasRemoteChanges(repo.current().dir)).toBe(false);
  });

  test('returns true when remote has new commits', async () => {
    const current = repo.current();
    await pushCommitToRemote(current.remoteDir, 'remote-file.txt');
    await runRealCommandResult(['jj', 'git', 'fetch', '--remote', 'origin'], { cwd: current.dir });
    expect(await hasRemoteChanges(current.dir)).toBe(true);
  });
});
