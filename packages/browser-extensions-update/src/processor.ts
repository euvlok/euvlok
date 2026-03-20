import { $ } from 'bun';
import { logger, exec, nixHashToSri } from '@euvlok/shared';
import { join } from 'pathe';
import { Listr } from 'listr2';
import pLimit from 'p-limit';
import type { BrowserType, Extension, ExtensionResult, GithubReleaseConfig } from './types';
import { getFileExtension } from './types';
import { fetchExtensionUrl } from './sources/index';
import { generateNixEntry } from './nix-entry';
import { extractManifestInfo } from './crx-parser';

export async function getChromiumMajorVersion(): Promise<string> {
  try {
    const output = await exec([
      'nix',
      'eval',
      '--impure',
      '--expr',
      'with import <nixpkgs> {}; lib.getVersion chromium',
    ]);
    const version = output.trim().replace(/"/g, '').split('.')[0];
    if (/^\d+$/.test(version)) return version;
  } catch {
    // ignore
  }

  logger.warn('Could not determine Chromium version, using default: 143');
  return '143';
}

export async function hash(path: string) {
  const hasher = new Bun.CryptoHasher('sha256');
  hasher.update(new Uint8Array(await Bun.file(path).arrayBuffer()));
  return nixHashToSri(hasher.digest('hex'));
}

export async function processExtension(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
): Promise<ExtensionResult> {
  const result = await fetchExtensionUrl(ext, config, browser, version);
  if (result.error) return { extension: ext, error: result.error };
  if (!result.url) return { extension: ext, error: 'Failed to get download URL' };

  const tmp = join(Bun.env.TMPDIR || '/tmp', `${crypto.randomUUID()}.${getFileExtension(browser)}`);

  const response = await fetch(result.url).catch(() => null);
  if (!response?.ok) {
    return { extension: ext, error: `Failed to download: HTTP ${response?.status ?? 'network error'}` };
  }
  await Bun.write(tmp, new Uint8Array(await response.arrayBuffer()));

  try {
    const sri = await hash(tmp);
    const manifest = await extractManifestInfo(tmp);

    const addon =
      browser === 'firefox' ? (manifest.addonId ?? result.addonId ?? ext.id) : undefined;

    if (browser === 'firefox' && addon && addon !== ext.id) {
      logger.info(`Resolved addonId for ${ext.id}: ${addon}`);
    }

    const entry = generateNixEntry(ext, result.url, sri, manifest.version, manifest.permissions, browser, addon);
    return { extension: ext, nixEntry: entry, version: manifest.version };
  } finally {
    await $`rm -f ${tmp}`.quiet();
  }
}

export async function processExtensionsWithProgress(
  extensions: Extension[],
  config: GithubReleaseConfig,
  browser: BrowserType,
  browserVersion?: string,
): Promise<ExtensionResult[]> {
  const results: ExtensionResult[] = new Array(extensions.length);
  const limit = pLimit(5);

  logger.info('');
  logger.info('Processing Extensions');

  const tasks = new Listr(
    extensions.map((ext, index) => ({
      title: `[${index + 1}/${extensions.length}] ${ext.name ?? ext.id}`,
      task: async (_ctx: unknown, task: { title: string }) => {
        const result = await limit(() => processExtension(ext, config, browser, browserVersion));
        results[index] = result;

        const status = result.error ? `FAIL: ${result.error}` : `v${result.version}`;
        task.title = `[${index + 1}/${extensions.length}] ${ext.name ?? ext.id} ${status}`;
      },
    })),
    { concurrent: 5, exitOnError: false },
  );

  await tasks.run();
  return results;
}
