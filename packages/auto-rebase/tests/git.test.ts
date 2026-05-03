import { afterEach, beforeEach, describe, expect, mock, spyOn, test } from 'bun:test';
import { join } from 'pathe';
import {
  cleanupTempDir,
  createTempGitRepo,
  createTempJjRepo,
  createTestContext,
  type JjTestRepo,
  mockCommandResult,
  runRealCommandResult,
  silentLogger,
} from './test-utils';

// Mock @euvlok/core with real runCommand by default (delegates to actual git).
// For specific fetchLatestRemoteState tests, we override to return controlled results.
const mockExecSafe = mock(runRealCommandResult);

mock.module('@euvlok/core', () => ({
  runCommandResult: mockExecSafe,
  logger: silentLogger,
}));

import { assertNoGitLocks, fetchLatestRemoteState, getOriginalBranch } from '../src/git';

describe('getOriginalBranch', () => {
  let tmpDir: string;

  beforeEach(async () => {
    mockExecSafe.mockImplementation(runRealCommandResult);
    tmpDir = await createTempGitRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  test('returns current branch name', async () => {
    await runRealCommandResult(['git', '-C', tmpDir, 'checkout', '-b', 'feature-test']);
    const result = await getOriginalBranch(tmpDir);
    expect(result).toBe('feature-test');
  });

  test('returns default branch after init', async () => {
    const result = await getOriginalBranch(tmpDir);
    // git init creates a default branch (master or main depending on config)
    expect(result).toBeTruthy();
    expect(result).not.toBe('HEAD');
  });

  test('returns HEAD for detached HEAD', async () => {
    const head = await runRealCommandResult(['git', '-C', tmpDir, 'rev-parse', 'HEAD']);
    await runRealCommandResult(['git', '-C', tmpDir, 'checkout', '--detach', head.stdout]);
    const result = await getOriginalBranch(tmpDir);
    expect(result).toBe('HEAD');
  });
});

describe('assertNoGitLocks', () => {
  let tmpDir: string;
  let sleepSpy: ReturnType<typeof spyOn>;

  beforeEach(async () => {
    mockExecSafe.mockImplementation(runRealCommandResult);
    tmpDir = await createTempGitRepo();
  });

  afterEach(async () => {
    sleepSpy?.mockRestore();
    await cleanupTempDir(tmpDir);
  });

  test('returns immediately when no locks', async () => {
    await expect(assertNoGitLocks(tmpDir)).resolves.toBeUndefined();
  });

  test('throws when locks persist after timeout', async () => {
    sleepSpy = spyOn(Bun, 'sleep').mockResolvedValue(undefined);
    await Bun.write(join(tmpDir, '.git', 'index.lock'), '');

    await expect(assertNoGitLocks(tmpDir)).rejects.toThrow('Git locks still present');
  });

  test('returns when lock clears during polling', async () => {
    const lockPath = join(tmpDir, '.git', 'index.lock');
    await Bun.write(lockPath, '');

    let sleepCount = 0;
    sleepSpy = spyOn(Bun, 'sleep').mockImplementation(async () => {
      sleepCount++;
      if (sleepCount === 2) {
        // Simulate lock being released mid-wait
        await Bun.file(lockPath).delete();
      }
    });

    await expect(assertNoGitLocks(tmpDir)).resolves.toBeUndefined();
  });

  test('detects HEAD.lock too', async () => {
    sleepSpy = spyOn(Bun, 'sleep').mockResolvedValue(undefined);
    await Bun.write(join(tmpDir, '.git', 'HEAD.lock'), '');

    await expect(assertNoGitLocks(tmpDir)).rejects.toThrow('Git locks still present');
  });
});

describe('fetchLatestRemoteState', () => {
  afterEach(() => {
    mockExecSafe.mockImplementation(runRealCommandResult);
  });

  test('dry-run skips all runCommand calls', async () => {
    mockExecSafe.mockReset();
    mockExecSafe.mockImplementation(() => Promise.resolve(mockCommandResult()));
    const ctx = createTestContext({ dryRun: true });
    await fetchLatestRemoteState(ctx);
    expect(mockExecSafe).not.toHaveBeenCalled();
  });

  describe('with real repos', () => {
    let tmpDir: string;
    let repo: JjTestRepo;

    afterEach(async () => {
      if (tmpDir) await cleanupTempDir(tmpDir);
      if (repo) {
        await cleanupTempDir(repo.dir);
        await cleanupTempDir(repo.remoteDir);
      }
    });

    test('throws when no remote configured', async () => {
      mockExecSafe.mockImplementation(runRealCommandResult);
      tmpDir = await createTempGitRepo();
      const ctx = createTestContext({ repoRoot: tmpDir });
      await expect(fetchLatestRemoteState(ctx)).rejects.toThrow("No 'origin' remote configured");
    });

    test('fetch succeeds with real local remote', async () => {
      mockExecSafe.mockImplementation(runRealCommandResult);
      repo = await createTempJjRepo();
      const ctx = createTestContext({ repoRoot: repo.dir });
      await expect(fetchLatestRemoteState(ctx)).resolves.toBeUndefined();
    });
  });

  test('throws when jj git fetch fails', async () => {
    mockExecSafe.mockReset();
    const repo = await createTempJjRepo();
    const ctx = createTestContext({ repoRoot: repo.dir });
    mockExecSafe
      .mockResolvedValueOnce(mockCommandResult()) // jj bookmark track
      .mockResolvedValueOnce(mockCommandResult({ exitCode: 1 })); // jj git fetch fails
    await expect(
      fetchLatestRemoteState(ctx).finally(async () => {
        await cleanupTempDir(repo.dir);
        await cleanupTempDir(repo.remoteDir);
      }),
    ).rejects.toThrow('Failed to fetch from git remote');
  });
});
