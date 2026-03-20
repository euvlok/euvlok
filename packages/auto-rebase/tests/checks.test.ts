import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { join } from 'pathe';
import {
  realExec,
  silentLogger,
  cleanupTempDir,
  createTempJjRepo,
  pushCommitToRemote,
  type JjTestRepo,
} from './test-utils';

import { mock } from 'bun:test';

mock.module('@euvlok/shared', () => ({
  execSafe: realExec,
  logger: silentLogger,
}));

import { getRemoteBookmark, checkLocalChanges, checkRemoteChanges } from '../src/checks';

describe('getRemoteBookmark', () => {
  let repo: JjTestRepo;

  beforeEach(async () => {
    repo = await createTempJjRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(repo.dir);
    await cleanupTempDir(repo.remoteDir);
  });

  test('returns master@origin for repo with master branch', async () => {
    expect(await getRemoteBookmark(repo.dir)).toBe('master@origin');
  });

  test('falls back to remote_bookmarks() when no common bookmarks exist', async () => {
    // Rename master to something uncommon on the remote
    await realExec(['git', '-C', repo.remoteDir, 'branch', '-m', 'master', 'uncommon-branch']);
    // Re-fetch so jj sees the new branch name
    await realExec(['jj', 'git', 'fetch', '--remote', 'origin'], { cwd: repo.dir });
    const result = await getRemoteBookmark(repo.dir);
    expect(result).toBe('uncommon-branch@origin');
  });
});

describe('checkLocalChanges', () => {
  let repo: JjTestRepo;

  beforeEach(async () => {
    repo = await createTempJjRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(repo.dir);
    await cleanupTempDir(repo.remoteDir);
  });

  test('returns false when clean and in sync with remote', async () => {
    expect(await checkLocalChanges(repo.dir)).toBe(false);
  });

  test('returns true when working copy has modifications', async () => {
    await Bun.write(join(repo.dir, 'README'), 'modified\n');
    expect(await checkLocalChanges(repo.dir)).toBe(true);
  });

  test('returns true when working copy has new files', async () => {
    await Bun.write(join(repo.dir, 'new-file.txt'), 'new content\n');
    expect(await checkLocalChanges(repo.dir)).toBe(true);
  });

  test('returns true when local commit ahead of remote', async () => {
    await Bun.write(join(repo.dir, 'local.txt'), 'local\n');
    await realExec(['jj', 'new', '-m', 'local commit'], { cwd: repo.dir });
    expect(await checkLocalChanges(repo.dir)).toBe(true);
  });
});

describe('checkRemoteChanges', () => {
  let repo: JjTestRepo;

  beforeEach(async () => {
    repo = await createTempJjRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(repo.dir);
    await cleanupTempDir(repo.remoteDir);
  });

  test('returns false when remote is in sync', async () => {
    expect(await checkRemoteChanges(repo.dir)).toBe(false);
  });

  test('returns true when remote has new commits', async () => {
    await pushCommitToRemote(repo.remoteDir, 'remote-file.txt');
    await realExec(['jj', 'git', 'fetch', '--remote', 'origin'], { cwd: repo.dir });
    expect(await checkRemoteChanges(repo.dir)).toBe(true);
  });
});
