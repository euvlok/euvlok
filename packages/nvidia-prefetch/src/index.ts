import { exec, logger } from '@euvlok/shared';
import { buildApplication, buildCommand, run } from '@stricli/core';
import { join } from 'pathe';
import { fetchDriverHash, fetchGithubHash } from './hash';
import { getCurrentVersion, updateNvidiaDriverNix } from './nix-file';
import { AARCH64_BASE_URL, fetchLatestVersion, X86_64_BASE_URL } from './version';

type NvidiaPrefetchFlags = {
  update: boolean;
};

type DriverHashes = {
  sha256: string;
  sha256_aarch64: string;
  openSha256: string;
  settingsSha256: string;
  persistencedSha256: string;
};

async function resolveVersion(requestedVersion?: string): Promise<string> {
  const version = requestedVersion ?? (await fetchLatestVersion());
  if (!requestedVersion) logger.success(`Using latest driver version: ${version}`);
  return version;
}

async function exitIfCurrent(update: boolean, version: string): Promise<void> {
  if (!update) return;

  const current = await getCurrentVersion();
  if (current !== version) return;

  logger.info(`Current version (${current}) is already up to date`);
  logger.info('Use --no-update to force hash recalculation');
  process.exit(0);
}

async function createTempDir(): Promise<string> {
  return exec(['mktemp', '-d', `${join(Bun.env.TMPDIR || '/tmp', 'nvidia-prefetch-')}XXXXXX`]);
}

async function fetchHashes(version: string, tempDir: string): Promise<DriverHashes> {
  logger.info(`Fetching hashes for NVIDIA driver version ${version}...`);

  const sha256 = await fetchDriverHash('x86_64', X86_64_BASE_URL, version, tempDir);
  const sha256_aarch64 = await fetchDriverHash('aarch64', AARCH64_BASE_URL, version, tempDir);

  logger.info('Fetching NVIDIA open kernel modules...');
  const openSha256 = await fetchGithubHash('open-gpu-kernel-modules', version);

  logger.info('Fetching nvidia-settings...');
  const settingsSha256 = await fetchGithubHash('nvidia-settings', version);

  logger.info('Fetching nvidia-persistenced...');
  const persistencedSha256 = await fetchGithubHash('nvidia-persistenced', version);

  return { sha256, sha256_aarch64, openSha256, settingsSha256, persistencedSha256 };
}

function logHashes(hashes: DriverHashes): void {
  logger.log('');
  logger.success('Hash computation completed!');
  logger.log('');

  logger.log(`sha256 = "${hashes.sha256}";`);
  logger.log(`sha256_aarch64 = "${hashes.sha256_aarch64}";`);
  logger.log(`openSha256 = "${hashes.openSha256}";`);
  logger.log(`settingsSha256 = "${hashes.settingsSha256}";`);
  logger.log(`persistencedSha256 = "${hashes.persistencedSha256}";`);
}

async function updateNixIfRequested(update: boolean, version: string, hashes: DriverHashes) {
  if (!update) return;

  logger.log('');
  await updateNvidiaDriverNix(
    version,
    hashes.sha256,
    hashes.sha256_aarch64,
    hashes.openSha256,
    hashes.settingsSha256,
    hashes.persistencedSha256,
  );
}

const command = buildCommand<NvidiaPrefetchFlags, [string?]>({
  docs: {
    brief: 'Fetch NVIDIA driver hashes and update the Nix expression',
    fullDescription:
      'Fetches and computes SHA256 hashes for NVIDIA driver packages and related repositories.',
  },
  parameters: {
    flags: {
      update: {
        kind: 'boolean',
        brief: 'Update the nvidia-driver.nix file after computing hashes.',
        default: true,
      },
    },
    positional: {
      kind: 'tuple',
      parameters: [
        {
          parse: String,
          brief: 'NVIDIA driver version. Defaults to the latest available version.',
          placeholder: 'version',
          optional: true,
        },
      ],
    },
  },
  async func(args, requestedVersion) {
    const update = args.update;
    const version = await resolveVersion(requestedVersion);
    await exitIfCurrent(update, version);

    const tempDir = await createTempDir();
    await fetchHashes(version, tempDir)
      .then(async (hashes) => {
        logHashes(hashes);
        await updateNixIfRequested(update, version, hashes);
      })
      .finally(async () => {
        await exec(['rm', '-rf', tempDir]);
        logger.info('Cleaned up temporary directory');
      });
  },
});

const app = buildApplication(command, {
  name: 'nvidia-prefetch',
  scanner: {
    caseStyle: 'allow-kebab-for-camel',
  },
});

await run(app, Bun.argv.slice(2), { process });
