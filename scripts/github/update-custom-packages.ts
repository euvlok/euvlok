import { basename, resolve } from 'node:path';
import {
  commitAndPush,
  currentRefName,
  hasGitDiff,
  actionsLogger as logger,
  runSequentialTasks,
  walkFiles,
} from '@euvlok/github';
import {
  addGitPaths,
  escapeNixString,
  execSafe,
  nixEvalRaw,
  stagedShortstat,
} from '@euvlok/shared';

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

await runSequentialTasks(nixFiles, String, updatePackage);

if (!(await hasGitDiff())) {
  logger.info('No changes detected in any packages.');
  process.exit(0);
}

await commitAndPush({
  title: 'chore(pkgs): update custom packages',
  body: `The following package updates were applied:\n\n${await formatStagedShortstat()}`,
  add: [packageRoot],
  refName: currentRefName(),
});

async function updatePackage(nixFile: string): Promise<void> {
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
    return;
  }
  logger.warn(`Update script failed for ${nixFile}, skipping.`);
}

async function isDerivation(absPath: string): Promise<boolean> {
  const result = await nixEvalRaw(
    `with import <nixpkgs> {}; (callPackage "${escapeNixString(absPath)}" {}).type`,
  );

  return result === 'derivation';
}

async function hasSrc(absPath: string): Promise<boolean> {
  return (
    (await nixEvalRaw(
      `with import <nixpkgs> {}; (callPackage "${escapeNixString(absPath)}" {}).src`,
    )) !== null
  );
}

async function formatStagedShortstat(): Promise<string> {
  await addGitPaths(packageRoot);
  const stdout = await stagedShortstat();
  return stdout ? `    ${stdout}` : '    Updated package definitions.';
}
