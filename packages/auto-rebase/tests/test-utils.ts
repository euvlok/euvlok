import { afterEach, beforeEach } from 'bun:test';
import type { ExecResult } from '@euvlok/shared';
import { $ } from 'bun';
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
export async function realExec(cmd: string[], opts?: { cwd?: string }): Promise<ExecResult> {
  const result = Bun.spawn(cmd, { cwd: opts?.cwd, stdout: 'pipe', stderr: 'pipe' });
  const exitCode = await result.exited;
  const stdout = await new Response(result.stdout).text();
  const stderr = await new Response(result.stderr).text();
  return { stdout: stdout.trim(), stderr: stderr.trim(), exitCode };
}

function tempPath(prefix: string): string {
  return join('/tmp', `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2)}`);
}

async function configureGitUser(dir: string): Promise<void> {
  await $`git -C ${dir} config user.email "test@test.com"`.quiet();
  await $`git -C ${dir} config user.name "Test"`.quiet();
}

export async function createTempGitRepo(): Promise<string> {
  const dir = tempPath('test-repo');
  await $`mkdir -p ${dir}`.quiet();
  await $`git -C ${dir} init`.quiet();
  await configureGitUser(dir);
  await Bun.write(join(dir, '.gitkeep'), '');
  await $`git -C ${dir} add .`.quiet();
  await $`git -C ${dir} commit -m "init"`.quiet();
  return dir;
}

export async function createTempDir(): Promise<string> {
  const dir = tempPath('test-dir');
  await $`mkdir -p ${dir}`.quiet();
  return dir;
}

export async function cleanupTempDir(dir: string): Promise<void> {
  if (dir.startsWith('/tmp/')) await $`rm -rf ${dir}`.quiet();
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
  await $`git init --bare ${remoteDir}`.quiet();

  const dir = tempPath('test-jj');
  await $`mkdir -p ${dir}`.quiet();
  await $`git -C ${dir} init`.quiet();
  await configureGitUser(dir);
  await $`git -C ${dir} remote add origin ${remoteDir}`.quiet();
  await Bun.write(join(dir, 'README'), 'init\n');
  await $`git -C ${dir} add README`.quiet();
  await $`git -C ${dir} commit -m "init"`.quiet();
  await $`git -C ${dir} push origin master`.quiet();

  await $`jj git init --git-repo=.`.cwd(dir).quiet();
  await $`jj bookmark track master --remote=origin`.cwd(dir).quiet();

  return { dir, remoteDir };
}

export async function pushCommitToRemote(remoteDir: string, filename?: string): Promise<void> {
  const tmpClone = tempPath('test-clone');
  await $`git clone ${remoteDir} ${tmpClone}`.quiet();
  await configureGitUser(tmpClone);
  const fname = filename ?? `remote-${Date.now()}.txt`;
  await Bun.write(join(tmpClone, fname), 'remote change\n');
  await $`git -C ${tmpClone} add .`.quiet();
  await $`git -C ${tmpClone} commit -m "remote commit"`.quiet();
  await $`git -C ${tmpClone} push origin master`.quiet();
  await $`rm -rf ${tmpClone}`.quiet();
}
