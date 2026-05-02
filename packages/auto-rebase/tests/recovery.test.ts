import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { $ } from 'bun';
import { join } from 'pathe';
import { cleanupTempDir, createTempDir, realExec, silentLogger, useTempJjRepo } from './test-utils';

mock.module('@euvlok/shared', () => ({
  execSafe: realExec,
  logger: silentLogger,
}));

import { recoverFromInterruptedState } from '../src/recovery';

describe('recoverFromInterruptedState', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await createTempDir();
    await $`mkdir -p ${join(tmpDir, '.git')}`.quiet();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  test('returns true when no state file exists', async () => {
    expect(await recoverFromInterruptedState(tmpDir)).toBe(true);
  });

  test('recovers without .jj directory', async () => {
    await Bun.write(join(tmpDir, '.auto-rebase-state'), JSON.stringify(testState()));

    const result = await recoverFromInterruptedState(tmpDir);

    expect(result).toBe(true);
    expect(await Bun.file(join(tmpDir, '.auto-rebase-state')).exists()).toBe(false);
  });

  test('cleans up real diff files during recovery', async () => {
    const stagedDiff = join(tmpDir, 'staged.diff');
    const unstagedDiff = join(tmpDir, 'unstaged.diff');
    await Bun.write(stagedDiff, 'diff content');
    await Bun.write(unstagedDiff, 'diff content');

    await Bun.write(
      join(tmpDir, '.auto-rebase-state'),
      JSON.stringify(testState({ stagedDiffPath: stagedDiff, unstagedDiffPath: unstagedDiff })),
    );

    await recoverFromInterruptedState(tmpDir);

    expect(await Bun.file(stagedDiff).exists()).toBe(false);
    expect(await Bun.file(unstagedDiff).exists()).toBe(false);
  });
});

describe('recoverFromInterruptedState with real jj', () => {
  const repo = useTempJjRepo();

  test('recovers with real .jj directory present', async () => {
    const current = repo.current();
    await Bun.write(
      join(current.dir, '.auto-rebase-state'),
      JSON.stringify(testState({ originalBranch: 'master' })),
    );

    const result = await recoverFromInterruptedState(current.dir);

    expect(result).toBe(true);
    expect(await Bun.file(join(current.dir, '.auto-rebase-state')).exists()).toBe(false);
  });
});

function testState(overrides: Record<string, unknown> = {}) {
  return {
    originalBranch: 'main',
    originalHadStaged: false,
    originalStagedFiles: '',
    stagedDiffPath: '',
    unstagedDiffPath: '',
    jjWasPresent: false,
    timestamp: 1700000000,
    ...overrides,
  };
}
