import { computeFileSha256Sri, downloadToFile, logger, runCommandResult, withTempFilePath } from '@euvlok/core';
import { Listr } from 'listr2';
import { extractManifestInfo } from './crx-parser';
import { generateExtensionNixEntry } from './nix-entry';
import { resolveExtensionDownloadUrl } from './sources/index';
import type { BrowserType, Extension, ExtensionResult, GithubReleaseConfig } from './types';
import { getBrowserDownloadFileExtension } from './types';

export async function getChromiumMajorVersion(): Promise<string> {
  const output = await runCommandResult([
    'nix',
    'eval',
    '--raw',
    '--impure',
    '--expr',
    'let flake = builtins.getFlake (toString ./.); system = builtins.currentSystem; pkgs = import flake.inputs.nixpkgs { inherit system; config.allowUnfree = true; }; in pkgs.lib.getVersion pkgs.chromium',
  ]);
  const version = output.stdout.trim().split('.')[0];
  if (output.exitCode === 0 && /^\d+$/.test(version)) return version;

  logger.warn('Could not determine pinned Chromium version, using default: 143');
  return '143';
}

async function downloadExtension(url: string, path: string): Promise<string | null> {
  return downloadToFile(url, path)
    .then(() => null)
    .catch((error) => (error instanceof Error ? error.message : String(error)));
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
  const sri = await computeFileSha256Sri(tmp);
  const manifest = await extractManifestInfo(tmp);
  const addon = resolveAddonId(ext, browser, manifest.addonId, addonId);
  const entry = generateExtensionNixEntry(ext, url, sri, manifest.version, manifest.permissions, browser, addon);

  return { extension: ext, nixEntry: entry, version: manifest.version };
}

async function processExtension(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
): Promise<ExtensionResult> {
  const result = await resolveExtensionDownloadUrl(ext, config, browser, version);
  if (result.error) return { extension: ext, error: result.error };
  if (!result.url) return { extension: ext, error: 'Failed to get download URL' };
  const url = result.url;

  return withTempFilePath(getBrowserDownloadFileExtension(browser), async (tmp) => {
    const downloadError = await downloadExtension(url, tmp);
    if (downloadError) return { extension: ext, error: downloadError };

    return buildExtensionResult(ext, browser, url, result.addonId, tmp);
  });
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
