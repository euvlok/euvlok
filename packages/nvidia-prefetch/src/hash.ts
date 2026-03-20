import { logger, exec } from '@euvlok/shared';
import { join } from 'pathe';
import { GITHUB_BASE_URL } from './version';

export async function sri(filePath: string): Promise<string> {
  return exec(['nix-hash', '--flat', '--base32', '--type', 'sha256', '--sri', filePath]);
}

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
  await exec(['curl', '-fL', driverUrl, '-o', driverPath]);
  return sri(driverPath);
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
  const result = JSON.parse(output);
  return result.hash;
}
