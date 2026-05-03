import { afterEach, beforeEach, describe, expect, mock, test } from 'bun:test';
import {
  cleanupTempDir,
  createTempDir,
  createTempGitRepo,
  createTestContext,
  runRealCommandOrThrow,
  runRealCommandResult,
  silentLogger,
} from './test-utils';

mock.module('@euvlok/core', () => ({
  runCommand: runRealCommandOrThrow,
  runCommandResult: runRealCommandResult,
  logger: silentLogger,
}));

import { createRebaseBackup } from '../src/backup';

describe('createRebaseBackup', () => {
  let repoDir: string;
  let backupDir: string;

  beforeEach(async () => {
    repoDir = await createTempGitRepo();
    backupDir = await createTempDir();
  });

  afterEach(async () => {
    await cleanupTempDir(repoDir);
    await cleanupTempDir(backupDir);
  });

  test('creates a valid git bundle', async () => {
    const ctx = createTestContext({ repoRoot: repoDir, backupDir });
    const result = await createRebaseBackup(ctx);

    expect(result).toContain(backupDir);
    expect(result).toEndWith('.gitbundle');
    expect(await Bun.file(result).exists()).toBe(true);

    // Verify the bundle is actually valid
    const verify = await runRealCommandResult(['git', 'bundle', 'verify', result]);
    expect(verify.exitCode).toBe(0);
  });

  test('dry run returns empty string without creating files', async () => {
    const ctx = createTestContext({ repoRoot: repoDir, backupDir, dryRun: true });
    const result = await createRebaseBackup(ctx);
    expect(result).toBe('');
  });

  test('empty repo (no commits) returns empty string', async () => {
    const emptyDir = await createTempDir();
    await runRealCommandResult(['git', 'init', emptyDir]);
    await runRealCommandResult(['git', '-C', emptyDir, 'config', 'user.email', 'test@test.com']);
    await runRealCommandResult(['git', '-C', emptyDir, 'config', 'user.name', 'Test']);

    const ctx = createTestContext({ repoRoot: emptyDir, backupDir });
    const result = await createRebaseBackup(ctx);
    expect(result).toBe('');

    await cleanupTempDir(emptyDir);
  });
});
