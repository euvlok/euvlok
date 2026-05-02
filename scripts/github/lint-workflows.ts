import { exec, execSafe } from '@euvlok/shared';
import { group, actionsLogger as logger } from './lib/logging';
import { listWorkflowFiles } from './lib/workflows';

const workflowFiles = await listWorkflowFiles();

await group('actionlint', async () => {
  await Promise.all(
    workflowFiles.map((workflowFile) =>
      exec(['node_modules/.bin/node-actionlint', workflowFile], { inheritOutput: true }),
    ),
  );
});

await group('zizmor', async () => {
  const runner = await findZizmorRunner();
  if (!runner) {
    logger.warn('Skipping zizmor because uvx, pipx, and cargo are unavailable.');
    return;
  }

  await exec([...runner, '--offline', '--no-progress', '--format=github', '.github/workflows'], {
    inheritOutput: true,
  });
});

async function findZizmorRunner(): Promise<string[] | null> {
  if ((await execSafe(['uvx', '--version'])).exitCode === 0) {
    return ['uvx', 'zizmor'];
  }

  if ((await execSafe(['pipx', '--version'])).exitCode === 0) {
    return ['pipx', 'run', 'zizmor'];
  }

  return null;
}
