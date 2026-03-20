import { defineCommand, runMain } from 'citty';
import { $ } from 'bun';
import { logger } from '@euvlok/shared';
import { join } from 'pathe';
import { fetchLatestVersion, X86_64_BASE_URL, AARCH64_BASE_URL } from './version';
import { fetchDriverHash, fetchGithubHash } from './hash';
import { getCurrentVersion, updateNvidiaDriverNix } from './nix-file';

const main = defineCommand({
  meta: {
    name: 'nvidia-prefetch',
    description:
      'Fetch and compute SHA256 hashes for NVIDIA driver packages and related repositories',
  },
  args: {
    version: {
      type: 'string',
      alias: 'v',
      description: 'Specify a particular NVIDIA driver version to fetch',
    },
    latest: {
      type: 'boolean',
      alias: 'l',
      description: 'Fetch the latest available NVIDIA driver version (default)',
      default: false,
    },
    'no-update': {
      type: 'boolean',
      description: 'Do not update the nvidia-driver.nix file, only print the hashes',
      default: false,
    },
  },
  async run({ args }) {
    let version = args.version || args._[0];
    const latest = args.latest;
    const update = !args['no-update'];

    if (version && latest) {
      logger.error('Cannot specify both --version and --latest');
      process.exit(1);
    }

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

runMain(main);
