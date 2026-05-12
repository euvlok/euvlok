import { runCommand, runCommandResult } from '@euvlok/core';
import { group, listWorkflowFiles, actionsLogger as logger } from '@euvlok/github';

const workflowFiles = await listWorkflowFiles();

await group('actionlint', async () => {
  await Promise.all(
    workflowFiles.map((workflowFile) =>
      runCommand(['node_modules/.bin/node-actionlint', workflowFile], { inheritOutput: true }),
    ),
  );
});

await group('zizmor', async () => {
  const runner = await findZizmorRunner();
  if (!runner) {
    logger.warn('Skipping zizmor because uvx, pipx, and cargo are unavailable.');
    return;
  }

  await runCommand([...runner, '--offline', '--no-progress', '--format=github', '.github/workflows'], {
    inheritOutput: true,
  });
});

async function findZizmorRunner(): Promise<string[] | null> {
  if ((await runCommandResult(['uvx', '--version'])).exitCode === 0) {
    return ['uvx', 'zizmor'];
  }

  if ((await runCommandResult(['pipx', '--version'])).exitCode === 0) {
    return ['pipx', 'run', 'zizmor'];
  }

  return null;
}
