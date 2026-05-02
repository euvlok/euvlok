import { logger } from '@euvlok/shared';
import { buildApplication, buildCommand, run } from '@stricli/core';
import { $ } from 'bun';
import { join } from 'pathe';
import { fetchDriverHash, fetchGithubHash } from './hash';
import { getCurrentVersion, updateNvidiaDriverNix } from './nix-file';
import { AARCH64_BASE_URL, fetchLatestVersion, X86_64_BASE_URL } from './version';

type NvidiaPrefetchFlags = {
  update: boolean;
};

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
    let version = requestedVersion;
    const update = args.update;

    if (!version) {
      version = await fetchLatestVersion();
      logger.success(`Using latest driver version: ${version}`);
    }

    if (update) {
      const current = await getCurrentVersion();
      if (current === version) {
        logger.info(`Current version (${current}) is already up to date`);
        logger.info('Use --no-update to force hash recalculation');
        process.exit(0);
      }
    }

    const tempDir = (
      await $`mktemp -d ${join(Bun.env.TMPDIR || '/tmp', 'nvidia-prefetch-')}XXXXXX`.text()
    ).trim();
    try {
      logger.info(`Fetching hashes for NVIDIA driver version ${version}...`);

      const sha256 = await fetchDriverHash('x86_64', X86_64_BASE_URL, version, tempDir);
      const sha256_aarch64 = await fetchDriverHash('aarch64', AARCH64_BASE_URL, version, tempDir);

      logger.info('Fetching NVIDIA open kernel modules...');
      const openSha256 = await fetchGithubHash('open-gpu-kernel-modules', version);

      logger.info('Fetching nvidia-settings...');
      const settingsSha256 = await fetchGithubHash('nvidia-settings', version);

      logger.info('Fetching nvidia-persistenced...');
      const persistencedSha256 = await fetchGithubHash('nvidia-persistenced', version);

      logger.log('');
      logger.success('Hash computation completed!');
      logger.log('');

      logger.log(`sha256 = "${sha256}";`);
      logger.log(`sha256_aarch64 = "${sha256_aarch64}";`);
      logger.log(`openSha256 = "${openSha256}";`);
      logger.log(`settingsSha256 = "${settingsSha256}";`);
      logger.log(`persistencedSha256 = "${persistencedSha256}";`);

      if (update) {
        logger.log('');
        await updateNvidiaDriverNix(
          version,
          sha256,
          sha256_aarch64,
          openSha256,
          settingsSha256,
          persistencedSha256,
        );
      }
    } finally {
      await $`rm -rf ${tempDir}`.quiet();
      logger.info('Cleaned up temporary directory');
    }
  },
});

const app = buildApplication(command, {
  name: 'nvidia-prefetch',
  scanner: {
    caseStyle: 'allow-kebab-for-camel',
  },
});

await run(app, Bun.argv.slice(2), { process });
