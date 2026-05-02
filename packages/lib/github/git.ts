import * as core from '@actions/core';
import { context } from '@actions/github';
import { simpleGit } from 'simple-git';
import { actionsLogger as logger } from './logging';

export type RefName = string;

export type CommitAndPushOptions = {
  title: string;
  body: string;
  add: readonly string[];
  refName: RefName;
};

const git = simpleGit({ trimmed: false });

export async function hasGitDiff(pathspecs: readonly string[] = []): Promise<boolean> {
  return !(await gitDiffQuiet(['--quiet', ...pathspecs]));
}

async function hasStagedChanges(): Promise<boolean> {
  return !(await gitDiffQuiet(['--staged', '--quiet']));
}

async function configureGitHubBot(): Promise<void> {
  await git.addConfig('user.name', 'github-actions[bot]', false, 'local');
  await git.addConfig(
    'user.email',
    '41898282+github-actions[bot]@users.noreply.github.com',
    false,
    'local',
  );
}

export async function commitAndPush(options: CommitAndPushOptions): Promise<void> {
  await configureGitHubBot();
  await configureAuthenticatedRemote();
  await git.add([...options.add]);

  if (!(await hasStagedChanges())) {
    logger.info('No staged changes remain after git add.');
    return;
  }

  await git.commit([options.title, options.body]);
  await pushWithRebaseRetry(options.refName);
}

async function configureAuthenticatedRemote(): Promise<void> {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    return;
  }

  core.setSecret(token);
  const remoteUrl = `https://x-access-token:${token}@github.com/${context.repo.owner}/${context.repo.repo}.git`;
  await git.remote(['set-url', 'origin', remoteUrl]);
}

export function currentRefName(fallback = 'master'): RefName {
  if (process.env.GITHUB_REF_NAME) {
    return process.env.GITHUB_REF_NAME;
  }

  if (context.ref?.startsWith('refs/heads/')) {
    return context.ref.slice('refs/heads/'.length);
  }

  return process.env.GITHUB_HEAD_REF ?? fallback;
}

async function pushWithRebaseRetry(refName: RefName): Promise<void> {
  await Array.from({ length: 5 }, (_, index) => index + 1).reduce(async (previous, attempt) => {
    if (await previous) return true;

    const pushed = await git
      .push('origin', `HEAD:${refName}`)
      .then(() => true)
      .catch(() => false);
    if (pushed) {
      logger.info(`Successfully pushed changes on attempt ${attempt}.`);
      return true;
    }

    if (attempt === 5) {
      throw new Error('Failed to push after 5 attempts.');
    }

    const waitSeconds = 5 * attempt;
    logger.warn(
      `Push failed on attempt ${attempt}. Waiting ${waitSeconds}s and retrying after rebase...`,
    );
    await Bun.sleep(waitSeconds * 1000);
    await git.pull('origin', refName, ['--rebase']);
    return false;
  }, Promise.resolve(false));
}

async function gitDiffQuiet(args: string[]): Promise<boolean> {
  return git
    .diff(args)
    .then(() => true)
    .catch(() => false);
}
