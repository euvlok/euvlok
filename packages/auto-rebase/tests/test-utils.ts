import { afterEach, beforeEach } from 'bun:test';
import { mkdir, rm } from 'node:fs/promises';
import type { CommandResult } from '@euvlok/core';
import { join } from 'pathe';
import type { RebaseContext } from '../src/context';

export function createTestContext(overrides?: Partial<RebaseContext>): RebaseContext {
  return {
    repoRoot: '/tmp/test-repo',
    dryRun: false,
    autoRebase: true,
    backupDir: '/tmp',
    jjWasPresent: false,
    cleanupNeeded: false,
    originalBranch: 'main',
    originalHadStaged: false,
    originalStagedFiles: '',
    stagedDiffPath: '',
    unstagedDiffPath: '',
    backupFile: '',
    ...overrides,
  };
}

export function mockCommandResult(overrides?: Partial<CommandResult>): CommandResult {
  return {
    stdout: '',
    stderr: '',
    exitCode: 0,
    ...overrides,
  };
}

/** Re-implementation of runCommandResult for use in test mocks that need real shell execution. */
export async function runRealCommandResult(
  cmd: string[],
  opts?: { cwd?: string; trimOutput?: boolean },
): Promise<CommandResult> {
  const result = Bun.spawn(cmd, { cwd: opts?.cwd, stdout: 'pipe', stderr: 'pipe' });
  const exitCode = await result.exited;
  const stdout = await new Response(result.stdout).text();
  const stderr = await new Response(result.stderr).text();
  return normalizeCommandResult(stdout, stderr, exitCode, opts?.trimOutput ?? true);
}

/** Re-implementation of runCommand for use in test setup that should fail fast. */
export async function runRealCommandOrThrow(
  cmd: string[],
  opts?: { cwd?: string; trimOutput?: boolean },
): Promise<string> {
  const result = await runRealCommandResult(cmd, opts);
  if (result.exitCode !== 0) throw commandError(cmd, result);

  return result.stdout;
}

function normalizeCommandResult(stdout: string, stderr: string, exitCode: number, trim: boolean): CommandResult {
  return {
    stdout: maybeTrim(stdout, trim),
    stderr: maybeTrim(stderr, trim),
    exitCode,
  };
}

function maybeTrim(value: string, trim: boolean): string {
  return trim ? value.trim() : value;
}

function commandError(cmd: string[], result: CommandResult): Error {
  return new Error(`Command failed (exit ${result.exitCode}): ${cmd.join(' ')}\n${result.stderr}`);
}

function tempPath(prefix: string): string {
  return join('/tmp', `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`);
}

async function configureGitUser(dir: string): Promise<void> {
  await runRealCommandOrThrow(['git', '-C', dir, 'config', 'user.email', 'test@test.com']);
  await runRealCommandOrThrow(['git', '-C', dir, 'config', 'user.name', 'Test']);
}

export async function createTempGitRepo(): Promise<string> {
  const dir = tempPath('test-repo');
  await initGitRepo(dir);
  await Bun.write(join(dir, '.gitkeep'), '');
  await runRealCommandOrThrow(['git', '-C', dir, 'add', '.']);
  await runRealCommandOrThrow(['git', '-C', dir, 'commit', '-m', 'init']);
  return dir;
}

export async function createTempDir(): Promise<string> {
  const dir = tempPath('test-dir');
  await mkdir(dir, { recursive: true });
  return dir;
}

export async function cleanupTempDir(dir: string): Promise<void> {
  if (dir.startsWith('/tmp/')) await rm(dir, { recursive: true, force: true });
}

export function useTempDir(): { current: () => string } {
  let dir = '';

  beforeEach(async () => {
    dir = await createTempDir();
  });

  afterEach(async () => {
    await cleanupTempDir(dir);
    dir = '';
  });

  return {
    current: () => {
      if (!dir) throw new Error('Temporary directory has not been created');
      return dir;
    },
  };
}

export const silentLogger = {
  info: () => {},
  warn: () => {},
  error: () => {},
  success: () => {},
};

export interface JjTestRepo {
  dir: string;
  remoteDir: string;
}

export function useTempJjRepo(): { current: () => JjTestRepo } {
  let repo: JjTestRepo | undefined;

  beforeEach(async () => {
    repo = await createTempJjRepo();
  });

  afterEach(async () => {
    if (!repo) return;
    await cleanupTempJjRepo(repo);
    repo = undefined;
  });

  return {
    current: () => {
      if (!repo) throw new Error('Test jj repository has not been created');
      return repo;
    },
  };
}

export async function cleanupTempJjRepo(repo: JjTestRepo): Promise<void> {
  await cleanupTempDir(repo.dir);
  await cleanupTempDir(repo.remoteDir);
}

export async function createTempJjRepo(): Promise<JjTestRepo> {
  const remoteDir = tempPath('test-remote');
  await runRealCommandOrThrow(['git', 'init', '--bare', remoteDir]);

  const dir = tempPath('test-jj');
  await initGitRepo(dir);
  await runRealCommandOrThrow(['git', '-C', dir, 'remote', 'add', 'origin', remoteDir]);
  await Bun.write(join(dir, 'README'), 'init\n');
  await runRealCommandOrThrow(['git', '-C', dir, 'add', 'README']);
  await runRealCommandOrThrow(['git', '-C', dir, 'commit', '-m', 'init']);
  await runRealCommandOrThrow(['git', '-C', dir, 'push', 'origin', 'master']);

  await runRealCommandOrThrow(['jj', 'git', 'init', '--git-repo=.'], { cwd: dir });
  await runRealCommandOrThrow(['jj', 'bookmark', 'track', 'master', '--remote=origin'], {
    cwd: dir,
  });

  return { dir, remoteDir };
}

async function initGitRepo(dir: string): Promise<void> {
  await mkdir(dir, { recursive: true });
  await runRealCommandOrThrow(['git', '-C', dir, 'init']);
  await configureGitUser(dir);
}

export async function pushCommitToRemote(remoteDir: string, filename?: string): Promise<void> {
  const tmpClone = tempPath('test-clone');
  await runRealCommandOrThrow(['git', 'clone', remoteDir, tmpClone]);
  await configureGitUser(tmpClone);
  const fname = filename ?? `remote-${Date.now()}.txt`;
  await Bun.write(join(tmpClone, fname), 'remote change\n');
  await runRealCommandOrThrow(['git', '-C', tmpClone, 'add', '.']);
  await runRealCommandOrThrow(['git', '-C', tmpClone, 'commit', '-m', 'remote commit']);
  await runRealCommandOrThrow(['git', '-C', tmpClone, 'push', 'origin', 'master']);
  await rm(tmpClone, { recursive: true, force: true });
}
