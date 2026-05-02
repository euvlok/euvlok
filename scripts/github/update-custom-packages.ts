import { basename, resolve } from 'node:path';
import { escapeNixString, execSafe } from '@euvlok/shared';
import { simpleGit } from 'simple-git';
import { walkFiles } from './lib/files';
import { commitAndPush, currentRefName, hasGitDiff } from './lib/git';
import { group, actionsLogger as logger } from './lib/logging';

const packageRoot = 'pkgs';

if (!(await Bun.file(packageRoot).exists())) {
  logger.info('pkgs/ not found, skipping custom package updates.');
  process.exit(0);
}

const nixFiles = await walkFiles(packageRoot, (path) => path.endsWith('.nix'));

if (nixFiles.length === 0) {
  logger.info('No package derivations found under pkgs/.');
  process.exit(0);
}

for (const nixFile of nixFiles) {
  await group(`Processing ${nixFile}`, async () => {
    const absPath = resolve(nixFile);
    const name = basename(nixFile, '.nix');

    if (!(await isDerivation(absPath))) {
      logger.warn(`${nixFile} is NOT a derivation, skipping.`);
      return;
    }

    if (!(await hasSrc(absPath))) {
      logger.info(`${nixFile} does not have a .src attribute, skipping update.`);
      return;
    }

    logger.info(`${name} is a fetchable derivation, proceeding with update.`);

    const result = await execSafe(['bash', './pkgs/update.sh', nixFile], {
      inheritOutput: true,
    });

    if (result.exitCode === 0) {
      logger.info(`Update script succeeded for ${nixFile}`);
    } else {
      logger.warn(`Update script failed for ${nixFile}, skipping.`);
    }
  });
}

if (!(await hasGitDiff())) {
  logger.info('No changes detected in any packages.');
  process.exit(0);
}

await commitAndPush({
  title: 'chore(pkgs): update custom packages',
  body: `The following package updates were applied:\n\n${await stagedShortstat()}`,
  add: [packageRoot],
  refName: currentRefName(),
});

async function isDerivation(absPath: string): Promise<boolean> {
  const result = await execSafe([
    'nix',
    'eval',
    '--impure',
    '--raw',
    '--expr',
    `with import <nixpkgs> {}; (callPackage "${escapeNixString(absPath)}" {}).type`,
  ]);

  return result.exitCode === 0 && result.stdout === 'derivation';
}

async function hasSrc(absPath: string): Promise<boolean> {
  const result = await execSafe([
    'nix',
    'eval',
    '--impure',
    '--raw',
    '--expr',
    `with import <nixpkgs> {}; (callPackage "${escapeNixString(absPath)}" {}).src`,
  ]);

  return result.exitCode === 0;
}

async function stagedShortstat(): Promise<string> {
  const git = simpleGit();
  await git.add(packageRoot);
  const stdout = await git.raw(['diff', '--staged', '--shortstat']);
  return stdout ? `    ${stdout}` : '    Updated package definitions.';
}
