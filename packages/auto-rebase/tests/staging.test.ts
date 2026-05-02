import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import { join } from 'pathe';
import {
  cleanupTempDir,
  createTempGitRepo,
  realExec,
  realExecOrThrow,
  silentLogger,
  useTempDir,
} from './test-utils';

mock.module('@euvlok/shared', () => ({
  execSafe: realExec,
  logger: silentLogger,
}));

import { removeDiffFiles, restoreStaging } from '../src/staging';

async function writeFiles(tmpDir: string, files: Record<string, string>) {
  await Promise.all(
    Object.entries(files).map((entry) => Bun.write(join(tmpDir, entry[0]), entry[1])),
  );
}

async function commitFiles(tmpDir: string, files: Record<string, string>, message: string) {
  await writeFiles(tmpDir, files);
  await realExecOrThrow(['git', '-C', tmpDir, 'add', ...Object.keys(files)]);
  await realExecOrThrow(['git', '-C', tmpDir, 'commit', '-m', message]);
}

async function stageChanges(tmpDir: string, files: Record<string, string>) {
  await writeFiles(tmpDir, files);
  await realExecOrThrow(['git', '-C', tmpDir, 'add', ...Object.keys(files)]);
}

async function captureStagedDiff(tmpDir: string): Promise<{ diffPath: string; fileList: string }> {
  const diffPath = join(tmpDir, 'staged.diff');
  await Bun.write(
    diffPath,
    await realExecOrThrow(['git', '-C', tmpDir, 'diff', '--cached'], { trimOutput: false }),
  );
  const fileList = await realExecOrThrow(['git', '-C', tmpDir, 'diff', '--cached', '--name-only']);
  return { diffPath, fileList };
}

async function stagedFiles(tmpDir: string): Promise<string> {
  const result = await realExec(['git', '-C', tmpDir, 'diff', '--cached', '--name-only']);
  return result.stdout;
}

describe('restoreStaging', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await createTempGitRepo();
  });

  afterEach(async () => {
    await cleanupTempDir(tmpDir);
  });

  test('restores staged changes from diff file', async () => {
    await commitFiles(tmpDir, { 'file.ts': 'line1\n' }, 'add file');
    await stageChanges(tmpDir, { 'file.ts': 'line1\nline2\n' });
    const stagedDiff = await captureStagedDiff(tmpDir);
    await realExecOrThrow(['git', '-C', tmpDir, 'reset']);

    await restoreStaging(tmpDir, stagedDiff.diffPath, 'file.ts');

    expect(await stagedFiles(tmpDir)).toContain('file.ts');
  });

  test('restores staging for multiple files', async () => {
    await commitFiles(tmpDir, { 'a.ts': 'a\n', 'b.ts': 'b\n' }, 'add files');
    await stageChanges(tmpDir, { 'a.ts': 'a modified\n', 'b.ts': 'b modified\n' });
    const stagedDiff = await captureStagedDiff(tmpDir);
    await realExecOrThrow(['git', '-C', tmpDir, 'reset']);

    await restoreStaging(tmpDir, stagedDiff.diffPath, stagedDiff.fileList);

    const staged = await stagedFiles(tmpDir);
    expect(staged).toContain('a.ts');
    expect(staged).toContain('b.ts');
  });

  test('clears unrelated staged files before restoring original staged diff', async () => {
    await commitFiles(
      tmpDir,
      { 'original.ts': 'original\n', 'unrelated.ts': 'base\n' },
      'add files',
    );
    await stageChanges(tmpDir, { 'original.ts': 'original staged\n' });
    const stagedDiff = await captureStagedDiff(tmpDir);
    await realExecOrThrow(['git', '-C', tmpDir, 'reset']);
    await stageChanges(tmpDir, { 'unrelated.ts': 'should not stay staged\n' });

    await restoreStaging(tmpDir, stagedDiff.diffPath, stagedDiff.fileList);

    const staged = await stagedFiles(tmpDir);
    expect(staged).toContain('original.ts');
    expect(staged).not.toContain('unrelated.ts');
  });

  test('falls back to git add when diff file missing', async () => {
    await commitFiles(tmpDir, { 'file.ts': 'original\n' }, 'add file');
    await Bun.write(join(tmpDir, 'file.ts'), 'modified\n');

    await restoreStaging(tmpDir, '/nonexistent.diff', 'file.ts');

    expect(await stagedFiles(tmpDir)).toContain('file.ts');
  });

  test('handles empty file list gracefully', async () => {
    await restoreStaging(tmpDir, '', '');
    expect(await stagedFiles(tmpDir)).toBe('');
  });
});

describe('removeDiffFiles', () => {
  const tmpDir = useTempDir();

  test('removes existing diff files', async () => {
    const staged = join(tmpDir.current(), 'staged.diff');
    const unstaged = join(tmpDir.current(), 'unstaged.diff');
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
      removeDiffFiles(join(tmpDir.current(), 'nope1.diff'), join(tmpDir.current(), 'nope2.diff')),
    ).resolves.toBeUndefined();
  });
});
