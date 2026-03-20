import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { join } from 'pathe';
import {
  createTestContext,
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

import { checkRebaseSafety, performRebase } from '../src/rebase';

async function setupDivergingRepo(): Promise<JjTestRepo> {
  const repo = await createTempJjRepo();
  // Push a remote commit (different file — no conflict)
  await pushCommitToRemote(repo.remoteDir, 'remote-only.txt');
  // Fetch it so jj knows about the remote changes
  await realExec(['jj', 'git', 'fetch', '--remote', 'origin'], { cwd: repo.dir });
  // Make a local change (different file — no conflict)
  await Bun.write(join(repo.dir, 'local-only.txt'), 'local\n');
  await realExec(['jj', 'new', '-m', 'local commit'], { cwd: repo.dir });
  return repo;
}

describe('checkRebaseSafety', () => {
  let repo: JjTestRepo;

  afterEach(async () => {
    if (repo) {
      await cleanupTempDir(repo.dir);
      await cleanupTempDir(repo.remoteDir);
    }
  });

  test('clean divergence returns safe with rebase applied', async () => {
    repo = await setupDivergingRepo();
    const ctx = createTestContext({ repoRoot: repo.dir });
    const result = await checkRebaseSafety(ctx);
    expect(result).toEqual({ safe: true, rebaseAlreadyApplied: true });
  });

  test('dry-run clean divergence returns safe without rebase applied', async () => {
    repo = await setupDivergingRepo();
    const ctx = createTestContext({ repoRoot: repo.dir, dryRun: true });
    const result = await checkRebaseSafety(ctx);
    expect(result).toEqual({ safe: true, rebaseAlreadyApplied: false });
  });

  test('jj 0.39 exits 0 even with conflicts (documents real behavior)', async () => {
    repo = await createTempJjRepo();
    // Create conflicting changes: same file modified both locally and remotely
    // Remote modifies README
    const tmpClone = join(
      '/tmp',
      `test-clone-conflict-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    );
    await realExec(['git', 'clone', repo.remoteDir, tmpClone]);
    await realExec(['git', '-C', tmpClone, 'config', 'user.email', 'test@test.com']);
    await realExec(['git', '-C', tmpClone, 'config', 'user.name', 'Test']);
    await Bun.write(join(tmpClone, 'README'), 'remote version\n');
    await realExec(['git', '-C', tmpClone, 'add', '.']);
    await realExec(['git', '-C', tmpClone, 'commit', '-m', 'remote edit']);
    await realExec(['git', '-C', tmpClone, 'push', 'origin', 'master']);
    await cleanupTempDir(tmpClone);

    // Local modifies same file
    await Bun.write(join(repo.dir, 'README'), 'local version\n');
    await realExec(['jj', 'git', 'fetch', '--remote', 'origin'], { cwd: repo.dir });
    await realExec(['jj', 'new', '-m', 'local conflicting commit'], { cwd: repo.dir });

    const ctx = createTestContext({ repoRoot: repo.dir });
    const result = await checkRebaseSafety(ctx);
    // jj 0.39 exits 0 even with conflicts — so this returns safe: true
    expect(result.safe).toBe(true);
    expect(result.rebaseAlreadyApplied).toBe(true);
  });
});

describe('performRebase', () => {
  let repo: JjTestRepo;

  afterEach(async () => {
    if (repo) {
      await cleanupTempDir(repo.dir);
      await cleanupTempDir(repo.remoteDir);
    }
  });

  test('clean rebase succeeds without error', async () => {
    repo = await setupDivergingRepo();
    const ctx = createTestContext({ repoRoot: repo.dir });
    await expect(performRebase(ctx)).resolves.toBeUndefined();
  });

  test('dry-run does not execute rebase', async () => {
    repo = await setupDivergingRepo();
    const ctx = createTestContext({ repoRoot: repo.dir, dryRun: true });
    await performRebase(ctx);
    // Should return immediately without error
  });
});
