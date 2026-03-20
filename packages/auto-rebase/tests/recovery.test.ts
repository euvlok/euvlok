import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { join } from 'pathe';
import {
  createTempDir,
  cleanupTempDir,
  realExec,
  silentLogger,
  createTempJjRepo,
  type JjTestRepo,
} from './test-utils';
import { $ } from 'bun';

import { mock } from 'bun:test';

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
    const stateContent = [
      'ORIGINAL_BRANCH="main"',
      'ORIGINAL_HAD_STAGED="false"',
      'ORIGINAL_STAGED_FILES=""',
      'PATH_TO_STAGED_DIFF=""',
      'PATH_TO_UNSTAGED_DIFF=""',
      'JJ_WAS_PRESENT="false"',
      'TIMESTAMP=1700000000',
    ].join('\n');
    await Bun.write(join(tmpDir, '.auto-rebase-state'), stateContent);

    const result = await recoverFromInterruptedState(tmpDir);

    expect(result).toBe(true);
    expect(await Bun.file(join(tmpDir, '.auto-rebase-state')).exists()).toBe(false);
  });

  test('cleans up real diff files during recovery', async () => {
    const stagedDiff = join(tmpDir, 'staged.diff');
    const unstagedDiff = join(tmpDir, 'unstaged.diff');
    await Bun.write(stagedDiff, 'diff content');
    await Bun.write(unstagedDiff, 'diff content');

    const stateContent = [
      'ORIGINAL_BRANCH="main"',
      'ORIGINAL_HAD_STAGED="false"',
      'ORIGINAL_STAGED_FILES=""',
      `PATH_TO_STAGED_DIFF="${stagedDiff}"`,
      `PATH_TO_UNSTAGED_DIFF="${unstagedDiff}"`,
      'JJ_WAS_PRESENT="false"',
      'TIMESTAMP=1700000000',
    ].join('\n');
    await Bun.write(join(tmpDir, '.auto-rebase-state'), stateContent);

    await recoverFromInterruptedState(tmpDir);

    expect(await Bun.file(stagedDiff).exists()).toBe(false);
    expect(await Bun.file(unstagedDiff).exists()).toBe(false);
  });
});

describe('recoverFromInterruptedState with real jj', () => {
  let repo: JjTestRepo;

  beforeEach(async () => {
    repo = await createTempJjRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(repo.dir);
    await cleanupTempDir(repo.remoteDir);
  });

  test('recovers with real .jj directory present', async () => {
    const stateContent = [
      'ORIGINAL_BRANCH="master"',
      'ORIGINAL_HAD_STAGED="false"',
      'ORIGINAL_STAGED_FILES=""',
      'PATH_TO_STAGED_DIFF=""',
      'PATH_TO_UNSTAGED_DIFF=""',
      'JJ_WAS_PRESENT="false"',
      'TIMESTAMP=1700000000',
    ].join('\n');
    await Bun.write(join(repo.dir, '.auto-rebase-state'), stateContent);

    const result = await recoverFromInterruptedState(repo.dir);

    expect(result).toBe(true);
    expect(await Bun.file(join(repo.dir, '.auto-rebase-state')).exists()).toBe(false);
  });
});
