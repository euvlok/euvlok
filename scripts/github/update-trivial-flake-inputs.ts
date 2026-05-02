import { exec } from '@euvlok/shared';
import { commitAndPush, currentRefName, hasGitDiff } from './lib/git';
import { group, actionsLogger as logger } from './lib/logging';

type FlakeLock = {
  nodes?: Record<string, FlakeNode | undefined>;
};

type FlakeNode = {
  inputs?: Record<string, string>;
  locked?: {
    owner?: string;
    repo?: string;
    rev?: string;
  };
};

type InputSnapshot = {
  name: string;
  repo: string | null;
  rev: string;
};

const lockFile = Bun.file('flake.lock');

if (!(await lockFile.exists())) {
  logger.warn('flake.lock not found, skipping.');
  process.exit(0);
}

const before = (await lockFile.json()) as FlakeLock;
const trivialInputs = Object.keys(before.nodes?.root?.inputs ?? {})
  .filter((name) => name.endsWith('-trivial'))
  .sort((a, b) => a.localeCompare(b));

if (trivialInputs.length === 0) {
  logger.info('No trivial inputs found to update.');
  process.exit(0);
}

logger.info(`Found ${trivialInputs.length} trivial inputs: ${trivialInputs.join(' ')}`);

const oldSnapshots = new Map<string, InputSnapshot>(
  trivialInputs.map((name) => [name, snapshotInput(name, before)]),
);

await group('Updating trivial inputs', async () => {
  await exec(['nix', 'flake', 'update', ...trivialInputs], {
    inheritOutput: true,
    env: {
      NIX_CONFIG: 'extra-experimental-features = nix-command flakes pipe-operator',
    },
  });
});

if (!(await hasGitDiff(['flake.lock']))) {
  logger.info('No changes detected in flake.lock after update.');
  process.exit(0);
}

const after = (await lockFile.json()) as FlakeLock;
const changedInputs = trivialInputs.flatMap((name) => {
  const oldInput = oldSnapshots.get(name);
  const newInput = snapshotInput(name, after);

  if (!oldInput || shortRev(oldInput.rev) === shortRev(newInput.rev)) {
    return [];
  }

  const oldCommit = shortRev(oldInput.rev);
  const newCommit = shortRev(newInput.rev);
  if (newInput.repo) {
    return [
      `- ${name} (${oldCommit}...${newCommit}) - https://github.com/${newInput.repo}/compare/${oldCommit}...${newCommit}`,
    ];
  }

  return [`- ${name} (${oldCommit}...${newCommit})`];
});

const body = changedInputs.length > 0 ? changedInputs.join('\n') : 'Updated trivial flake inputs.';

await commitAndPush({
  title: 'chore: update trivial flake inputs',
  body,
  add: ['flake.lock'],
  refName: currentRefName(),
});

function snapshotInput(name: string, lock: FlakeLock): InputSnapshot {
  const locked = lock.nodes?.[name]?.locked;
  return {
    name,
    repo: repoPath(locked),
    rev: locked?.rev ?? 'unknown',
  };
}

function repoPath(locked: FlakeNode['locked']): string | null {
  if (!locked?.owner || !locked.repo) return null;
  return `${locked.owner}/${locked.repo}`;
}

function shortRev(rev: string): string {
  return rev.slice(0, 7);
}
