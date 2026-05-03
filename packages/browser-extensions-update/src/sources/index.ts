import type { MaybePromise } from '@euvlok/core';
import type {
  BrowserType,
  Extension,
  ExtensionDownloadUrlResult,
  ExtensionSource,
  GithubReleaseConfig,
} from '../types';
import { isExtensionSourceSupported } from '../types';
import { fetchAmoUrlAndGuid } from './amo';
import { fetchBpcUrl } from './bpc';
import { fetchChromeStoreUrl } from './chrome-store';
import { fetchGithubReleaseUrl } from './github-releases';
import { resolveConfiguredDownloadUrl } from './url';

type SourceFetcher = (
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
) => MaybePromise<ExtensionDownloadUrlResult>;

const sourceFetchers = {
  'chrome-store': (ext, _config, _browser, version) => fetchChromeStoreUrl(ext.id, version),
  amo: (ext) => fetchAmoUrlAndGuid(ext.id),
  bpc: (_ext, _config, browser) => fetchBpcUrl(browser),
  url: (ext) => resolveConfiguredDownloadUrl(ext),
  'github-releases': fetchGithubReleaseUrl,
} satisfies Record<ExtensionSource, SourceFetcher>;

export async function resolveExtensionDownloadUrl(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
): Promise<ExtensionDownloadUrlResult> {
  if (!isExtensionSourceSupported(browser, ext.source)) {
    return {
      error: `Source '${ext.source}' is not supported for ${browser} browser`,
    };
  }

  return sourceFetchers[ext.source](ext, config, browser, version);
}
