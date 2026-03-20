import { describe, test, expect, mock, beforeEach, afterEach, spyOn } from 'bun:test';
import { join } from 'pathe';
import {
  createTempGitRepo,
  cleanupTempDir,
  createTestContext,
  mockExecResult,
  realExec,
  silentLogger,
  createTempJjRepo,
  type JjTestRepo,
} from './test-utils';

// Mock @euvlok/shared with real exec by default (delegates to actual git).
// For specific fetchLatest tests, we override to return controlled results.
const mockExecSafe = mock(realExec);

mock.module('@euvlok/shared', () => ({
  execSafe: mockExecSafe,
  logger: silentLogger,
}));

import { getOriginalBranch, checkGitLocks, fetchLatest } from '../src/git';

describe('getOriginalBranch', () => {
  let tmpDir: string;

  beforeEach(async () => {
    mockExecSafe.mockImplementation(realExec);
    tmpDir = await createTempGitRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  test('returns current branch name', async () => {
    await realExec(['git', '-C', tmpDir, 'checkout', '-b', 'feature-test']);
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
    const { stdout: hash } = await realExec(['git', '-C', tmpDir, 'rev-parse', 'HEAD']);
    await realExec(['git', '-C', tmpDir, 'checkout', '--detach', hash]);
    const result = await getOriginalBranch(tmpDir);
    expect(result).toBe('HEAD');
  });
});

describe('checkGitLocks', () => {
  let tmpDir: string;
  let sleepSpy: ReturnType<typeof spyOn>;

  beforeEach(async () => {
    mockExecSafe.mockImplementation(realExec);
    tmpDir = await createTempGitRepo();
  });

  afterEach(async () => {
    sleepSpy?.mockRestore();
    await cleanupTempDir(tmpDir);
  });

  test('returns immediately when no locks', async () => {
    await expect(checkGitLocks(tmpDir)).resolves.toBeUndefined();
  });

  test('throws when locks persist after timeout', async () => {
    sleepSpy = spyOn(Bun, 'sleep').mockResolvedValue(undefined as any);
    await Bun.write(join(tmpDir, '.git', 'index.lock'), '');

    await expect(checkGitLocks(tmpDir)).rejects.toThrow('Git locks still present');
  });

  test('returns when lock clears during polling', async () => {
    const lockPath = join(tmpDir, '.git', 'index.lock');
    await Bun.write(lockPath, '');

    let sleepCount = 0;
    sleepSpy = spyOn(Bun, 'sleep').mockImplementation(async () => {
      sleepCount++;
      if (sleepCount === 2) {
        // Simulate lock being released mid-wait
        await Bun.$`rm -f ${lockPath}`.quiet();
      }
    });

    await expect(checkGitLocks(tmpDir)).resolves.toBeUndefined();
  });

  test('detects HEAD.lock too', async () => {
    sleepSpy = spyOn(Bun, 'sleep').mockResolvedValue(undefined as any);
    await Bun.write(join(tmpDir, '.git', 'HEAD.lock'), '');

    await expect(checkGitLocks(tmpDir)).rejects.toThrow('Git locks still present');
  });
});

describe('fetchLatest', () => {
  afterEach(() => {
    mockExecSafe.mockImplementation(realExec);
  });

  test('dry-run skips all exec calls', async () => {
    mockExecSafe.mockReset();
    mockExecSafe.mockImplementation(() => Promise.resolve(mockExecResult()));
    const ctx = createTestContext({ dryRun: true });
    await fetchLatest(ctx);
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
      mockExecSafe.mockImplementation(realExec);
      tmpDir = await createTempGitRepo();
      const ctx = createTestContext({ repoRoot: tmpDir });
      await expect(fetchLatest(ctx)).rejects.toThrow("No 'origin' remote configured");
    });

    test('fetch succeeds with real local remote', async () => {
      mockExecSafe.mockImplementation(realExec);
      repo = await createTempJjRepo();
      const ctx = createTestContext({ repoRoot: repo.dir });
      await expect(fetchLatest(ctx)).resolves.toBeUndefined();
    });
  });

  test('throws when jj git fetch fails', async () => {
    mockExecSafe.mockReset();
    const ctx = createTestContext();
    mockExecSafe
      .mockResolvedValueOnce(mockExecResult()) // remote get-url
      .mockResolvedValueOnce(mockExecResult()) // git fetch
      .mockResolvedValueOnce(mockExecResult()) // show-ref master found
      .mockResolvedValueOnce(mockExecResult()) // jj bookmark track
      .mockResolvedValueOnce(mockExecResult({ exitCode: 1 })); // jj git fetch fails
    await expect(fetchLatest(ctx)).rejects.toThrow('Failed to fetch from git remote');
  });
});
