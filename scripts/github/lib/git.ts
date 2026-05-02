import * as core from '@actions/core';
import { context } from '@actions/github';
import { exec, execSafe } from '@euvlok/shared';
import { actionsLogger as logger } from './logging';

export type RefName = string;

export interface CommitAndPushOptions {
  title: string;
  body: string;
  add: readonly string[];
  refName: RefName;
}

export async function hasGitDiff(pathspecs: readonly string[] = []): Promise<boolean> {
  const result = await execSafe(['git', 'diff', '--quiet', ...pathspecs]);
  return result.exitCode !== 0;
}

export async function hasStagedChanges(): Promise<boolean> {
  const result = await execSafe(['git', 'diff', '--staged', '--quiet']);
  return result.exitCode !== 0;
}

export async function listStagedFiles(): Promise<string[]> {
  const stdout = await exec(['git', 'diff', '--staged', '--name-only']);
  return stdout
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
}

export async function readGitBlob(ref: string, path: string): Promise<string> {
  const result = await execSafe(['git', 'show', `${ref}:${path}`], { trimOutput: false });
  return result.exitCode === 0 ? result.stdout : '';
}

export async function readGitIndex(path: string): Promise<string> {
  const result = await execSafe(['git', 'show', `:${path}`], { trimOutput: false });
  return result.exitCode === 0 ? result.stdout : '';
}

export async function configureGitHubBot(): Promise<void> {
  await exec(['git', 'config', '--local', 'user.name', 'github-actions[bot]']);
  await exec([
    'git',
    'config',
    '--local',
    'user.email',
    '41898282+github-actions[bot]@users.noreply.github.com',
  ]);
}

export async function commitAndPush(options: CommitAndPushOptions): Promise<void> {
  await configureGitHubBot();
  await configureAuthenticatedRemote();
  await exec(['git', 'add', ...options.add]);

  if (!(await hasStagedChanges())) {
    logger.info('No staged changes remain after git add.');
    return;
  }

  await exec(['git', 'commit', '-m', options.title, '-m', options.body], { inheritOutput: true });
  await pushWithRebaseRetry(options.refName);
}

async function configureAuthenticatedRemote(): Promise<void> {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    return;
  }

  core.setSecret(token);
  const remoteUrl = `https://x-access-token:${token}@github.com/${context.repo.owner}/${context.repo.repo}.git`;
  await exec(['git', 'remote', 'set-url', 'origin', remoteUrl]);
}

export function currentRefName(fallback = 'main'): RefName {
  if (process.env.GITHUB_REF_NAME) {
    return process.env.GITHUB_REF_NAME;
  }

  if (context.ref?.startsWith('refs/heads/')) {
    return context.ref.slice('refs/heads/'.length);
  }

  return process.env.GITHUB_HEAD_REF ?? fallback;
}

async function pushWithRebaseRetry(refName: RefName): Promise<void> {
  const maxAttempts = 5;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const push = await execSafe(['git', 'push', 'origin', `HEAD:${refName}`], {
      inheritOutput: true,
    });

    if (push.exitCode === 0) {
      logger.info(`Successfully pushed changes on attempt ${attempt}.`);
      return;
    }

    if (attempt === maxAttempts) {
      throw new Error(`Failed to push after ${maxAttempts} attempts.`);
    }

    const waitSeconds = 5 * attempt;
    logger.warn(
      `Push failed on attempt ${attempt}. Waiting ${waitSeconds}s and retrying after rebase...`,
    );
    await Bun.sleep(waitSeconds * 1000);
    await exec(['git', 'pull', '--rebase', 'origin', refName], { inheritOutput: true });
  }
}
