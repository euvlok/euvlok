import { $ } from 'bun';
import { logger, execSafe, escapeNixString, validateNixFile, findRepoRoot } from '@euvlok/shared';
import { join } from 'pathe';

async function find(): Promise<string | null> {
  const root = await findRepoRoot();
  if (!root) return null;

  const result = await execSafe([
    'find',
    root,
    '-name',
    'nvidia-driver.nix',
    '-type',
    'f',
    '-not',
    '-path',
    '*/.git/*',
    '-not',
    '-path',
    '*/.jj/*',
    '-not',
    '-path',
    '*/node_modules/*',
  ]);

  if (result.exitCode !== 0 || !result.stdout) return null;
  const path = result.stdout.split('\n')[0];
  return path && (await Bun.file(path).exists()) ? path : null;
}

export async function getCurrentVersion(): Promise<string | null> {
  const path = await find();
  if (!path) return null;

  const content = await Bun.file(path).text();
  const match = content.match(/^\s*version\s*=\s*"([^"]+)"/m);
  return match ? match[1] : null;
}

export async function updateNvidiaDriverNix(
  version: string,
  sha256_64bit: string,
  sha256_aarch64: string,
  openSha256: string,
  settingsSha256: string,
  persistencedSha256: string,
): Promise<void> {
  const path = await find();
  if (!path) {
    throw new Error(
      "Could not find modules/nixos/nvidia-driver.nix file. Make sure you're running this script from within the repository",
    );
  }

  logger.info(`Updating ${path}...`);

  const backup = `${path}.backup`;
  await Bun.write(backup, Bun.file(path));
  logger.info(`Created backup: ${backup}`);

  const content = `{
  version = "${escapeNixString(version)}";
  sha256_64bit = "${escapeNixString(sha256_64bit)}";
  sha256_aarch64 = "${escapeNixString(sha256_aarch64)}";
  openSha256 = "${escapeNixString(openSha256)}";
  settingsSha256 = "${escapeNixString(settingsSha256)}";
  persistencedSha256 = "${escapeNixString(persistencedSha256)}";
}
`;

  const tmp = join(Bun.env.TMPDIR || '/tmp', `nvidia-driver-${Date.now()}.nix`);
  await Bun.write(tmp, content);

  try {
    await validateNixFile(tmp);
  } catch {
    await Bun.write(path, Bun.file(backup));
    await $`rm -f ${tmp}`.quiet();
    await $`rm -f ${backup}`.quiet();
    throw new Error('Generated nix file is invalid, restored backup');
  }

  await Bun.write(path, Bun.file(tmp));
  await $`rm -f ${tmp}`.quiet();
  await $`rm -f ${backup}`.quiet();

  logger.success(`Successfully updated ${path}`);
}
