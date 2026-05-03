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

/**
 * Check whether git reports a diff for the provided pathspecs.
 */
export async function hasUnstagedGitDiff(pathspecs: readonly string[] = []): Promise<boolean> {
  return !(await gitDiffQuiet(['--quiet', ...pathspecs]));
}

/**
 * Check whether the git index contains staged changes.
 */
async function hasStagedChanges(): Promise<boolean> {
  return !(await gitDiffQuiet(['--staged', '--quiet']));
}

/**
 * Configure the local repository to author commits as the GitHub Actions bot.
 */
async function configureGitHubBot(): Promise<void> {
  await git.addConfig('user.name', 'github-actions[bot]', false, 'local');
  await git.addConfig(
    'user.email',
    '41898282+github-actions[bot]@users.noreply.github.com',
    false,
    'local',
  );
}

/**
 * Stage, commit, and push generated changes to a branch.
 */
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

/**
 * Use GITHUB_TOKEN to make the origin remote writable from GitHub Actions.
 */
async function configureAuthenticatedRemote(): Promise<void> {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    return;
  }

  core.setSecret(token);
  const remoteUrl = `https://x-access-token:${token}@github.com/${context.repo.owner}/${context.repo.repo}.git`;
  await git.remote(['set-url', 'origin', remoteUrl]);
}

/**
 * Resolve the branch name for the current GitHub Actions ref.
 */
export function getCurrentRefName(fallback = 'master'): RefName {
  if (process.env.GITHUB_REF_NAME) {
    return process.env.GITHUB_REF_NAME;
  }

  if (context.ref?.startsWith('refs/heads/')) {
    return context.ref.slice('refs/heads/'.length);
  }

  return process.env.GITHUB_HEAD_REF ?? fallback;
}

/**
 * Push to the target ref, rebasing and retrying if the remote moved.
 */
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

/**
 * Run git diff in quiet mode and return whether it exits successfully.
 */
async function gitDiffQuiet(args: string[]): Promise<boolean> {
  return git
    .diff(args)
    .then(() => true)
    .catch(() => false);
}
