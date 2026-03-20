import { $ } from 'bun';
import { join } from 'pathe';
import type { RebaseContext } from '../src/context';
import type { ExecResult } from '@euvlok/shared';

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

export async function createTempGitRepo(): Promise<string> {
  const dir = join('/tmp', `test-repo-${Date.now()}-${Math.random().toString(36).slice(2)}`);
  await $`mkdir -p ${dir}`.quiet();
  await $`git -C ${dir} init`.quiet();
  await $`git -C ${dir} config user.email "test@test.com"`.quiet();
  await $`git -C ${dir} config user.name "Test"`.quiet();
  await Bun.write(join(dir, '.gitkeep'), '');
  await $`git -C ${dir} add .`.quiet();
  await $`git -C ${dir} commit -m "init"`.quiet();
  return dir;
}

export async function createTempDir(): Promise<string> {
  const dir = join('/tmp', `test-dir-${Date.now()}-${Math.random().toString(36).slice(2)}`);
  await $`mkdir -p ${dir}`.quiet();
  return dir;
}

export async function cleanupTempDir(dir: string): Promise<void> {
  if (dir.startsWith('/tmp/')) await $`rm -rf ${dir}`.quiet();
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

export async function createTempJjRepo(): Promise<JjTestRepo> {
  const remoteDir = join(
    '/tmp',
    `test-remote-${Date.now()}-${Math.random().toString(36).slice(2)}`,
  );
  await $`git init --bare ${remoteDir}`.quiet();

  const dir = join('/tmp', `test-jj-${Date.now()}-${Math.random().toString(36).slice(2)}`);
  await $`mkdir -p ${dir}`.quiet();
  await $`git -C ${dir} init`.quiet();
  await $`git -C ${dir} config user.email "test@test.com"`.quiet();
  await $`git -C ${dir} config user.name "Test"`.quiet();
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
  const tmpClone = join('/tmp', `test-clone-${Date.now()}-${Math.random().toString(36).slice(2)}`);
  await $`git clone ${remoteDir} ${tmpClone}`.quiet();
  await $`git -C ${tmpClone} config user.email "test@test.com"`.quiet();
  await $`git -C ${tmpClone} config user.name "Test"`.quiet();
  const fname = filename ?? `remote-${Date.now()}.txt`;
  await Bun.write(join(tmpClone, fname), 'remote change\n');
  await $`git -C ${tmpClone} add .`.quiet();
  await $`git -C ${tmpClone} commit -m "remote commit"`.quiet();
  await $`git -C ${tmpClone} push origin master`.quiet();
  await $`rm -rf ${tmpClone}`.quiet();
}
