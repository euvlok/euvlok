import { afterEach, beforeEach, describe, expect, spyOn, test } from 'bun:test';
import { stat } from 'node:fs/promises';
import { join } from 'pathe';
import { EUVLOK_TMP_DIR } from '../src/constants';
import { assertJjAvailable, setupJj } from '../src/jj';
import { cleanupTempDir, createTempGitRepo, createTestContext, runRealCommandOrThrow } from './test-utils';

describe('assertJjAvailable', () => {
  let whichSpy: ReturnType<typeof spyOn>;

  afterEach(() => {
    whichSpy?.mockRestore();
  });

  test('throws a clear error when jj is unavailable', () => {
    whichSpy = spyOn(Bun, 'which').mockReturnValue(null);

    expect(() => assertJjAvailable()).toThrow('Jujutsu (jj) is required for auto-rebase');
  });
});

describe('setupJj', () => {
  let repoDir: string;

  beforeEach(async () => {
    repoDir = await createTempGitRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(repoDir);
  });

  test('uses a temp directory that does not collide with the .euvlok marker file', async () => {
    const branch = await runRealCommandOrThrow(['git', '-C', repoDir, 'branch', '--show-current']);
    await Bun.write(join(repoDir, '.euvlok'), '');
    await Bun.write(join(repoDir, 'staged.txt'), 'staged\n');
    await runRealCommandOrThrow(['git', '-C', repoDir, 'add', 'staged.txt']);

    const ctx = createTestContext({ repoRoot: repoDir, originalBranch: branch });

    await expect(setupJj(ctx)).resolves.toBeUndefined();
    expect((await stat(join(repoDir, EUVLOK_TMP_DIR))).isDirectory()).toBe(true);
  });
});
