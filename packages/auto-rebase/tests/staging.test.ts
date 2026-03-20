import { describe, test, expect, mock, beforeEach, afterEach } from 'bun:test';
import { $ } from 'bun';
import { join } from 'pathe';
import {
  createTempGitRepo,
  createTempDir,
  cleanupTempDir,
  realExec,
  silentLogger,
} from './test-utils';

mock.module('@euvlok/shared', () => ({
  execSafe: realExec,
  logger: silentLogger,
}));

import { restoreStaging, removeDiffFiles } from '../src/staging';

describe('restoreStaging', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await createTempGitRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  test('restores staged changes from diff file', async () => {
    // Create a file and commit
    await Bun.write(join(tmpDir, 'file.ts'), 'line1\n');
    await $`git -C ${tmpDir} add file.ts`.quiet();
    await $`git -C ${tmpDir} commit -m "add file"`.quiet();

    // Modify and stage
    await Bun.write(join(tmpDir, 'file.ts'), 'line1\nline2\n');
    await $`git -C ${tmpDir} add file.ts`.quiet();

    // Capture staged diff (use $ to preserve trailing newline for git apply)
    const diffPath = join(tmpDir, 'staged.diff');
    const diffOutput = await $`git -C ${tmpDir} diff --cached`.text();
    await Bun.write(diffPath, diffOutput);

    // Unstage everything (simulates what happens during rebase)
    await $`git -C ${tmpDir} reset`.quiet();

    // Restore staging using the captured diff
    await restoreStaging(tmpDir, diffPath, 'file.ts');

    // Verify the file is staged again
    const stagedFiles = await realExec(['git', '-C', tmpDir, 'diff', '--cached', '--name-only']);
    expect(stagedFiles.stdout).toContain('file.ts');
  });

  test('restores staging for multiple files', async () => {
    // Create two files and commit
    await Bun.write(join(tmpDir, 'a.ts'), 'a\n');
    await Bun.write(join(tmpDir, 'b.ts'), 'b\n');
    await $`git -C ${tmpDir} add a.ts b.ts`.quiet();
    await $`git -C ${tmpDir} commit -m "add files"`.quiet();

    // Modify both and stage
    await Bun.write(join(tmpDir, 'a.ts'), 'a modified\n');
    await Bun.write(join(tmpDir, 'b.ts'), 'b modified\n');
    await $`git -C ${tmpDir} add a.ts b.ts`.quiet();

    // Capture diff and file list
    const diffPath = join(tmpDir, 'staged.diff');
    const diffOutput = await $`git -C ${tmpDir} diff --cached`.text();
    await Bun.write(diffPath, diffOutput);
    const fileList = (await $`git -C ${tmpDir} diff --cached --name-only`.text()).trim();

    // Unstage
    await $`git -C ${tmpDir} reset`.quiet();

    // Restore
    await restoreStaging(tmpDir, diffPath, fileList);

    // Verify both files re-staged
    const stagedFiles = await realExec(['git', '-C', tmpDir, 'diff', '--cached', '--name-only']);
    expect(stagedFiles.stdout).toContain('a.ts');
    expect(stagedFiles.stdout).toContain('b.ts');
  });

  test('falls back to git add when diff file missing', async () => {
    // Create and commit a file
    await Bun.write(join(tmpDir, 'file.ts'), 'original\n');
    await $`git -C ${tmpDir} add file.ts`.quiet();
    await $`git -C ${tmpDir} commit -m "add file"`.quiet();

    // Modify without staging
    await Bun.write(join(tmpDir, 'file.ts'), 'modified\n');

    // Call with non-existent diff path — should fall back to git add
    await restoreStaging(tmpDir, '/nonexistent.diff', 'file.ts');

    const stagedFiles = await realExec(['git', '-C', tmpDir, 'diff', '--cached', '--name-only']);
    expect(stagedFiles.stdout).toContain('file.ts');
  });

  test('handles empty file list gracefully', async () => {
    await restoreStaging(tmpDir, '', '');
    // Should not throw, no files staged
    const stagedFiles = await realExec(['git', '-C', tmpDir, 'diff', '--cached', '--name-only']);
    expect(stagedFiles.stdout).toBe('');
  });
});

describe('removeDiffFiles', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await createTempDir();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  test('removes existing diff files', async () => {
    const staged = join(tmpDir, 'staged.diff');
    const unstaged = join(tmpDir, 'unstaged.diff');
    await Bun.write(staged, 'diff content');
    await Bun.write(unstaged, 'diff content');

    await removeDiffFiles(staged, unstaged);

    expect(await Bun.file(staged).exists()).toBe(false);
    expect(await Bun.file(unstaged).exists()).toBe(false);
  });

  test('handles empty paths without error', async () => {
    await expect(removeDiffFiles('', '')).resolves.toBeUndefined();
  });

  test('handles non-existent files without error', async () => {
    await expect(
      removeDiffFiles(join(tmpDir, 'nope1.diff'), join(tmpDir, 'nope2.diff')),
    ).resolves.toBeUndefined();
  });
});
