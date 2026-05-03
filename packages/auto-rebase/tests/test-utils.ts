import { afterEach, beforeEach } from 'bun:test';
import { mkdir, rm } from 'node:fs/promises';
import type { ExecResult } from '@euvlok/shared';
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

export function mockExecResult(overrides?: Partial<ExecResult>): ExecResult {
  return {
    stdout: '',
    stderr: '',
    exitCode: 0,
    ...overrides,
  };
}

/** Re-implementation of execSafe for use in test mocks that need real shell execution. */
export async function realExec(
  cmd: string[],
  opts?: { cwd?: string; trimOutput?: boolean },
): Promise<ExecResult> {
  const result = Bun.spawn(cmd, { cwd: opts?.cwd, stdout: 'pipe', stderr: 'pipe' });
  const exitCode = await result.exited;
  const stdout = await new Response(result.stdout).text();
  const stderr = await new Response(result.stderr).text();
  const trim = opts?.trimOutput ?? true;
  return {
    stdout: trim ? stdout.trim() : stdout,
    stderr: trim ? stderr.trim() : stderr,
    exitCode,
  };
}

/** Re-implementation of exec for use in test setup that should fail fast. */
export async function realExecOrThrow(
  cmd: string[],
  opts?: { cwd?: string; trimOutput?: boolean },
): Promise<string> {
  const result = await realExec(cmd, opts);
  if (result.exitCode !== 0) {
    throw new Error(`Command failed (exit ${result.exitCode}): ${cmd.join(' ')}\n${result.stderr}`);
  }

  return result.stdout;
}

function tempPath(prefix: string): string {
  return join('/tmp', `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`);
}

async function configureGitUser(dir: string): Promise<void> {
  await realExecOrThrow(['git', '-C', dir, 'config', 'user.email', 'test@test.com']);
  await realExecOrThrow(['git', '-C', dir, 'config', 'user.name', 'Test']);
}

export async function createTempGitRepo(): Promise<string> {
  const dir = tempPath('test-repo');
  await mkdir(dir, { recursive: true });
  await realExecOrThrow(['git', '-C', dir, 'init']);
  await configureGitUser(dir);
  await Bun.write(join(dir, '.gitkeep'), '');
  await realExecOrThrow(['git', '-C', dir, 'add', '.']);
  await realExecOrThrow(['git', '-C', dir, 'commit', '-m', 'init']);
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
  await realExecOrThrow(['git', 'init', '--bare', remoteDir]);

  const dir = tempPath('test-jj');
  await mkdir(dir, { recursive: true });
  await realExecOrThrow(['git', '-C', dir, 'init']);
  await configureGitUser(dir);
  await realExecOrThrow(['git', '-C', dir, 'remote', 'add', 'origin', remoteDir]);
  await Bun.write(join(dir, 'README'), 'init\n');
  await realExecOrThrow(['git', '-C', dir, 'add', 'README']);
  await realExecOrThrow(['git', '-C', dir, 'commit', '-m', 'init']);
  await realExecOrThrow(['git', '-C', dir, 'push', 'origin', 'master']);

  await realExecOrThrow(['jj', 'git', 'init', '--git-repo=.'], { cwd: dir });
  await realExecOrThrow(['jj', 'bookmark', 'track', 'master', '--remote=origin'], { cwd: dir });

  return { dir, remoteDir };
}

export async function pushCommitToRemote(remoteDir: string, filename?: string): Promise<void> {
  const tmpClone = tempPath('test-clone');
  await realExecOrThrow(['git', 'clone', remoteDir, tmpClone]);
  await configureGitUser(tmpClone);
  const fname = filename ?? `remote-${Date.now()}.txt`;
  await Bun.write(join(tmpClone, fname), 'remote change\n');
  await realExecOrThrow(['git', '-C', tmpClone, 'add', '.']);
  await realExecOrThrow(['git', '-C', tmpClone, 'commit', '-m', 'remote commit']);
  await realExecOrThrow(['git', '-C', tmpClone, 'push', 'origin', 'master']);
  await rm(tmpClone, { recursive: true, force: true });
}
