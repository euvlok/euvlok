import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { join } from 'pathe';
import { getStateFilePath, loadState, saveState, removeState } from '../src/state';
import { createTempDir, cleanupTempDir } from './test-utils';

describe('state', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await createTempDir();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  describe('getStateFilePath', () => {
    test('returns correct path', () => {
      expect(getStateFilePath('/repo')).toBe('/repo/.auto-rebase-state');
    });
  });

  describe('loadState', () => {
    test('returns null when file does not exist', async () => {
      expect(await loadState(tmpDir)).toBeNull();
    });

    test('parses valid state file', async () => {
      const content = [
        'ORIGINAL_BRANCH="feature-branch"',
        'ORIGINAL_HAD_STAGED="true"',
        'ORIGINAL_STAGED_FILES="src/foo.ts"',
        'PATH_TO_STAGED_DIFF="/tmp/staged-123.diff"',
        'PATH_TO_UNSTAGED_DIFF="/tmp/unstaged-123.diff"',
        'JJ_WAS_PRESENT="false"',
        'TIMESTAMP=1700000000',
      ].join('\n');

      await Bun.write(join(tmpDir, '.auto-rebase-state'), content);
      const state = await loadState(tmpDir);

      expect(state).not.toBeNull();
      expect(state!.originalBranch).toBe('feature-branch');
      expect(state!.originalHadStaged).toBe(true);
      expect(state!.originalStagedFiles).toBe('src/foo.ts');
      expect(state!.stagedDiffPath).toBe('/tmp/staged-123.diff');
      expect(state!.unstagedDiffPath).toBe('/tmp/unstaged-123.diff');
      expect(state!.jjWasPresent).toBe(false);
      expect(state!.timestamp).toBe(1700000000);
    });

    test('handles missing fields with defaults', async () => {
      await Bun.write(join(tmpDir, '.auto-rebase-state'), 'TIMESTAMP=1700000000\n');
      const state = await loadState(tmpDir);

      expect(state).not.toBeNull();
      expect(state!.originalBranch).toBe('HEAD');
      expect(state!.originalHadStaged).toBe(false);
      expect(state!.originalStagedFiles).toBe('');
      expect(state!.stagedDiffPath).toBe('');
      expect(state!.unstagedDiffPath).toBe('');
      expect(state!.jjWasPresent).toBe(false);
    });

    test('returns non-null for empty file (HEAD default is truthy)', async () => {
      await Bun.write(join(tmpDir, '.auto-rebase-state'), '');
      expect(await loadState(tmpDir)).not.toBeNull();
    });
  });

  describe('saveState', () => {
    test('writes correct key=value format', async () => {
      await saveState(tmpDir, {
        originalBranch: 'main',
        originalHadStaged: true,
        originalStagedFiles: 'file.ts',
        stagedDiffPath: '/tmp/staged.diff',
        unstagedDiffPath: '/tmp/unstaged.diff',
        jjWasPresent: false,
        timestamp: 1700000000,
      });

      const content = await Bun.file(join(tmpDir, '.auto-rebase-state')).text();
      expect(content).toContain('ORIGINAL_BRANCH="main"');
      expect(content).toContain('ORIGINAL_HAD_STAGED="true"');
      expect(content).toContain('ORIGINAL_STAGED_FILES="file.ts"');
      expect(content).toContain('PATH_TO_STAGED_DIFF="/tmp/staged.diff"');
      expect(content).toContain('PATH_TO_UNSTAGED_DIFF="/tmp/unstaged.diff"');
      expect(content).toContain('JJ_WAS_PRESENT="false"');
      expect(content).toContain('TIMESTAMP=1700000000');
    });
  });

  describe('round-trip', () => {
    test('saveState then loadState preserves all fields', async () => {
      const state = {
        originalBranch: 'feature/test',
        originalHadStaged: true,
        originalStagedFiles: 'a.ts',
        stagedDiffPath: '/tmp/staged-999.diff',
        unstagedDiffPath: '/tmp/unstaged-999.diff',
        jjWasPresent: true,
        timestamp: 1700000099,
      };

      await saveState(tmpDir, state);
      const loaded = await loadState(tmpDir);

      expect(loaded).not.toBeNull();
      expect(loaded!.originalBranch).toBe(state.originalBranch);
      expect(loaded!.originalHadStaged).toBe(state.originalHadStaged);
      expect(loaded!.originalStagedFiles).toBe(state.originalStagedFiles);
      expect(loaded!.stagedDiffPath).toBe(state.stagedDiffPath);
      expect(loaded!.unstagedDiffPath).toBe(state.unstagedDiffPath);
      expect(loaded!.jjWasPresent).toBe(state.jjWasPresent);
      expect(loaded!.timestamp).toBe(state.timestamp);
    });
  });

  describe('removeState', () => {
    test('removes existing state file', async () => {
      const stateFile = join(tmpDir, '.auto-rebase-state');
      await Bun.write(stateFile, 'test');
      expect(await Bun.file(stateFile).exists()).toBe(true);

      await removeState(tmpDir);
      expect(await Bun.file(stateFile).exists()).toBe(false);
    });

    test('does not throw for non-existent file', async () => {
      await expect(removeState(tmpDir)).resolves.toBeUndefined();
    });
  });
});
