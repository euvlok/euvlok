import { logger } from '@euvlok/shared';
import * as cheerio from 'cheerio';
import semver from 'semver';

export const X86_64_BASE_URL = 'https://download.nvidia.com/XFree86/Linux-x86_64';
export const AARCH64_BASE_URL = 'https://download.nvidia.com/XFree86/Linux-aarch64';
export const GITHUB_BASE_URL = 'https://github.com/NVIDIA';

export async function fetchVersionsFromPlatform(url: string, name: string): Promise<string[]> {
  logger.info(`Checking ${name} platform...`);

  const response = await fetch(`${url}/`);
  const html = await response.text();

  const $ = cheerio.load(html);
  const versions = $('a')
    .map((_index, link) => $(link).attr('href')?.replace(/\/$/, '') ?? '')
    .get()
    .filter((href): href is string => semver.valid(href) !== null)
    .sort(semver.compare);

  if (versions.length === 0) {
    throw new Error(`Could not fetch versions from ${name} platform`);
  }

  return versions;
}

export function findCommonLatestVersion(versions1: string[], versions2: string[]): string | null {
  const set2 = new Set(versions2);
  const common = versions1.filter((v) => set2.has(v));

  if (common.length === 0) return null;

  common.sort(semver.compare);

  return common[common.length - 1];
}

export async function fetchLatestVersion(): Promise<string> {
  logger.info('Fetching latest NVIDIA driver version from all platforms...');

  const x86 = await fetchVersionsFromPlatform(X86_64_BASE_URL, 'x86_64');
  const aarch = await fetchVersionsFromPlatform(AARCH64_BASE_URL, 'aarch64');

  const latest = findCommonLatestVersion(x86, aarch);
  if (!latest) {
    throw new Error(
      'Could not find a version available on both platforms. Please specify a version manually using --version flag',
    );
  }

  return latest;
}
