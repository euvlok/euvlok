import { logger } from '@euvlok/core';
import * as cheerio from 'cheerio';

export const X86_64_BASE_URL = 'https://download.nvidia.com/XFree86/Linux-x86_64';
export const AARCH64_BASE_URL = 'https://download.nvidia.com/XFree86/Linux-aarch64';
export const GITHUB_BASE_URL = 'https://github.com/NVIDIA';

function parseNvidiaVersion(version: string): number[] | null {
  if (!/^\d+(?:\.\d+)+$/.test(version)) return null;
  return version.split('.').map(Number);
}

export function compareNvidiaVersions(a: string, b: string): number {
  const parsedA = parseComparableNvidiaVersion(a, b);
  const parsedB = parseComparableNvidiaVersion(b, a);

  return compareVersionParts(parsedA, parsedB) ?? 0;
}

function parseComparableNvidiaVersion(version: string, other: string): number[] {
  const parsed = parseNvidiaVersion(version);
  if (parsed) return parsed;
  throw new Error(`Cannot compare invalid NVIDIA driver versions: ${version}, ${other}`);
}

function compareVersionParts(a: number[], b: number[]): number | null {
  const length = Math.max(a.length, b.length);
  const index = Array.from({ length }).findIndex((_, current) => (a[current] ?? 0) !== (b[current] ?? 0));

  return index === -1 ? null : (a[index] ?? 0) - (b[index] ?? 0);
}

async function fetchVersionsFromPlatform(url: string, name: string): Promise<string[]> {
  logger.info(`Checking ${name} platform...`);

  const response = await fetch(`${url}/`);
  const html = await response.text();

  const $ = cheerio.load(html);
  const versions = $('a')
    .map((_index, link) => $(link).attr('href')?.replace(/\/$/, '') ?? '')
    .get()
    .filter((href): href is string => parseNvidiaVersion(href) !== null)
    .sort(compareNvidiaVersions);

  if (versions.length === 0) {
    throw new Error(`Could not fetch versions from ${name} platform`);
  }

  return versions;
}

export function findLatestSharedNvidiaVersion(versions1: string[], versions2: string[]): string | null {
  const set2 = new Set(versions2);
  const common = versions1.filter((v) => set2.has(v));

  if (common.length === 0) return null;

  common.sort(compareNvidiaVersions);

  return common[common.length - 1];
}

export async function fetchLatestNvidiaVersion(): Promise<string> {
  logger.info('Fetching latest NVIDIA driver version from all platforms...');

  const x86 = await fetchVersionsFromPlatform(X86_64_BASE_URL, 'x86_64');
  const aarch = await fetchVersionsFromPlatform(AARCH64_BASE_URL, 'aarch64');

  const latest = findLatestSharedNvidiaVersion(x86, aarch);
  if (!latest) {
    throw new Error(
      'Could not find a version available on both platforms. Please specify a version manually using --version flag',
    );
  }

  return latest;
}
