import { execSafe, logger, nixHashToSri } from '@euvlok/shared';
import { $ } from 'bun';
import { Listr } from 'listr2';
import { join } from 'pathe';
import { extractManifestInfo } from './crx-parser';
import { generateNixEntry } from './nix-entry';
import { fetchExtensionUrl } from './sources/index';
import type { BrowserType, Extension, ExtensionResult, GithubReleaseConfig } from './types';
import { getFileExtension } from './types';

export async function getChromiumMajorVersion(): Promise<string> {
  const output = await execSafe([
    'nix',
    'eval',
    '--impure',
    '--expr',
    'with import <nixpkgs> {}; lib.getVersion chromium',
  ]);
  const version = output.stdout.trim().replace(/"/g, '').split('.')[0];
  if (output.exitCode === 0 && /^\d+$/.test(version)) return version;

  logger.warn('Could not determine Chromium version, using default: 143');
  return '143';
}

async function hash(path: string) {
  const hasher = new Bun.CryptoHasher('sha256');
  hasher.update(new Uint8Array(await Bun.file(path).arrayBuffer()));
  return nixHashToSri(hasher.digest('hex'));
}

function tempExtensionPath(browser: BrowserType): string {
  return join(Bun.env.TMPDIR || '/tmp', `${crypto.randomUUID()}.${getFileExtension(browser)}`);
}

async function downloadExtension(url: string, path: string): Promise<string | null> {
  const response = await fetch(url).catch(() => null);
  if (!response?.ok) return `Failed to download: HTTP ${response?.status ?? 'network error'}`;

  await Bun.write(path, new Uint8Array(await response.arrayBuffer()));
  return null;
}

function resolveAddonId(
  ext: Extension,
  browser: BrowserType,
  manifestAddonId?: string,
  resultAddonId?: string,
): string | undefined {
  if (browser !== 'firefox') return undefined;

  const addon = manifestAddonId ?? resultAddonId ?? ext.id;
  if (addon !== ext.id) logger.info(`Resolved addonId for ${ext.id}: ${addon}`);
  return addon;
}

async function buildExtensionResult(
  ext: Extension,
  browser: BrowserType,
  url: string,
  addonId: string | undefined,
  tmp: string,
): Promise<ExtensionResult> {
  const sri = await hash(tmp);
  const manifest = await extractManifestInfo(tmp);
  const addon = resolveAddonId(ext, browser, manifest.addonId, addonId);
  const entry = generateNixEntry(
    ext,
    url,
    sri,
    manifest.version,
    manifest.permissions,
    browser,
    addon,
  );

  return { extension: ext, nixEntry: entry, version: manifest.version };
}

async function processExtension(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
): Promise<ExtensionResult> {
  const result = await fetchExtensionUrl(ext, config, browser, version);
  if (result.error) return { extension: ext, error: result.error };
  if (!result.url) return { extension: ext, error: 'Failed to get download URL' };

  const tmp = tempExtensionPath(browser);

  const downloadError = await downloadExtension(result.url, tmp);
  if (downloadError) return { extension: ext, error: downloadError };

  return buildExtensionResult(ext, browser, result.url, result.addonId, tmp).finally(() =>
    $`rm -f ${tmp}`.quiet(),
  );
}

export async function processExtensionsWithProgress(
  extensions: Extension[],
  config: GithubReleaseConfig,
  browser: BrowserType,
  browserVersion?: string,
): Promise<ExtensionResult[]> {
  const results: ExtensionResult[] = new Array(extensions.length);

  logger.info('');
  logger.info('Processing Extensions');

  const tasks = new Listr(
    extensions.map((ext, index) => ({
      title: `[${index + 1}/${extensions.length}] ${ext.name ?? ext.id}`,
      task: async (_ctx: unknown, task: { title: string }) => {
        const result = await processExtension(ext, config, browser, browserVersion);
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
