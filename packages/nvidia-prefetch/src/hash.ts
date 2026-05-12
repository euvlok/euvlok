import { computeFileSha256Sri, downloadToFile, logger, runCommand } from '@euvlok/core';
import { join } from 'pathe';
import { z } from 'zod';
import { GITHUB_BASE_URL } from './version';

const prefetchResultSchema = z.object({
  hash: z.string(),
});

export async function fetchDriverSha256Sri(
  arch: string,
  baseUrl: string,
  version: string,
  tempDir: string,
): Promise<string> {
  const driverName = `NVIDIA-Linux-${arch}-${version}.run`;
  const driverUrl = `${baseUrl}/${version}/${driverName}`;
  const driverPath = join(tempDir, driverName);

  logger.info(`Fetching ${arch} driver ${version}...`);
  await downloadToFile(driverUrl, driverPath);
  return computeFileSha256Sri(driverPath);
}

export async function prefetchGithubSourceHash(repo: string, version: string): Promise<string> {
  const url = `${GITHUB_BASE_URL}/${repo}/archive/${version}.tar.gz`;
  const output = await runCommand(['nix', 'store', 'prefetch-file', '--unpack', '--name', 'source', '--json', url]);
  const result = prefetchResultSchema.parse(JSON.parse(output));
  return result.hash;
}
