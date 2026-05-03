import { exec, logger, sha256SriFromFile } from '@euvlok/shared';
import { join } from 'pathe';
import { z } from 'zod';
import { GITHUB_BASE_URL } from './version';

const prefetchResultSchema = z.object({
  hash: z.string(),
});

export async function fetchDriverHash(
  arch: string,
  baseUrl: string,
  version: string,
  tempDir: string,
): Promise<string> {
  const driverName = `NVIDIA-Linux-${arch}-${version}.run`;
  const driverUrl = `${baseUrl}/${version}/${driverName}`;
  const driverPath = join(tempDir, driverName);

  logger.info(`Fetching ${arch} driver ${version}...`);
  await downloadFile(driverUrl, driverPath);
  return sha256SriFromFile(driverPath);
}

async function downloadFile(url: string, path: string): Promise<void> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download ${url}: HTTP ${response.status}`);
  }

  await Bun.write(path, new Uint8Array(await response.arrayBuffer()));
}

export async function fetchGithubHash(repo: string, version: string): Promise<string> {
  const url = `${GITHUB_BASE_URL}/${repo}/archive/${version}.tar.gz`;
  const output = await exec([
    'nix',
    'store',
    'prefetch-file',
    '--unpack',
    '--name',
    'source',
    '--json',
    url,
  ]);
  const result = prefetchResultSchema.parse(JSON.parse(output));
  return result.hash;
}
