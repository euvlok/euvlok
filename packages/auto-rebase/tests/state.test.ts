import { describe, expect, test } from 'bun:test';
import { join } from 'pathe';
import type { RebaseState } from '../src/state';
import { getStateFilePath, loadState, removeState, saveState } from '../src/state';
import { useTempDir } from './test-utils';

function stateFixture(overrides: Partial<RebaseState> = {}): RebaseState {
  return {
    originalBranch: 'feature/test',
    originalHadStaged: true,
    originalStagedFiles: 'a.ts',
    stagedDiffPath: '/tmp/staged-999.diff',
    unstagedDiffPath: '/tmp/unstaged-999.diff',
    jjWasPresent: true,
    timestamp: 1700000099,
    ...overrides,
  };
}

function expectStateFields(actual: RebaseState | null, expected: RebaseState): void {
  expect(actual).toEqual(expected);
}

describe('state', () => {
  const tmpDir = useTempDir();

  describe('getStateFilePath', () => {
    test('returns correct path', () => {
      expect(getStateFilePath('/repo')).toBe('/repo/.auto-rebase-state');
    });
  });

  describe('loadState', () => {
    test('returns null when file does not exist', async () => {
      expect(await loadState(tmpDir.current())).toBeNull();
    });

    test('parses valid state file', async () => {
      const expected = stateFixture({
        originalBranch: 'feature-branch',
        originalStagedFiles: 'src/foo.ts',
        stagedDiffPath: '/tmp/staged-123.diff',
        unstagedDiffPath: '/tmp/unstaged-123.diff',
        jjWasPresent: false,
        timestamp: 1700000000,
      });

      await Bun.write(join(tmpDir.current(), '.auto-rebase-state'), JSON.stringify(expected));

      expectStateFields(await loadState(tmpDir.current()), expected);
    });

    test('handles missing fields with defaults', async () => {
      await Bun.write(
        join(tmpDir.current(), '.auto-rebase-state'),
        JSON.stringify({ timestamp: 1700000000 }),
      );

      expect(await loadState(tmpDir.current())).toEqual({
        originalBranch: 'HEAD',
        originalHadStaged: false,
        originalStagedFiles: '',
        stagedDiffPath: '',
        unstagedDiffPath: '',
        jjWasPresent: false,
        timestamp: 1700000000,
      });
    });

    test('returns null for empty file', async () => {
      await Bun.write(join(tmpDir.current(), '.auto-rebase-state'), '');
      expect(await loadState(tmpDir.current())).toBeNull();
    });
  });

  describe('saveState', () => {
    test('writes JSON format', async () => {
      const state = stateFixture({
        originalBranch: 'main',
        originalStagedFiles: 'file.ts',
        stagedDiffPath: '/tmp/staged.diff',
        unstagedDiffPath: '/tmp/unstaged.diff',
        jjWasPresent: false,
        timestamp: 1700000000,
      });

      await saveState(tmpDir.current(), state);

      const content = await Bun.file(join(tmpDir.current(), '.auto-rebase-state')).text();
      expect(JSON.parse(content)).toEqual(state);
    });
  });

  describe('round-trip', () => {
    test('saveState then loadState preserves all fields', async () => {
      const state = stateFixture();

      await saveState(tmpDir.current(), state);

      expectStateFields(await loadState(tmpDir.current()), state);
    });
  });

  describe('removeState', () => {
    test('removes existing state file', async () => {
      const stateFile = join(tmpDir.current(), '.auto-rebase-state');
      await Bun.write(stateFile, 'test');
      expect(await Bun.file(stateFile).exists()).toBe(true);

      await removeState(tmpDir.current());
      expect(await Bun.file(stateFile).exists()).toBe(false);
    });

    test('does not throw for non-existent file', async () => {
      await expect(removeState(tmpDir.current())).resolves.toBeUndefined();
    });
  });
});
