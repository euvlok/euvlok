import type { MaybePromise } from '@euvlok/shared';
import type {
  BrowserType,
  Extension,
  ExtensionSource,
  FetchUrlResult,
  GithubReleaseConfig,
} from '../types';
import { supportsSource } from '../types';
import { fetchAmoUrlAndGuid } from './amo';
import { fetchBpcUrl } from './bpc';
import { fetchChromeStoreUrl } from './chrome-store';
import { fetchGithubReleaseUrl } from './github-releases';
import { fetchUrlSource } from './url';

type SourceFetcher = (
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
) => MaybePromise<FetchUrlResult>;

const sourceFetchers = {
  'chrome-store': (ext, _config, _browser, version) => fetchChromeStoreUrl(ext.id, version),
  amo: (ext) => fetchAmoUrlAndGuid(ext.id),
  bpc: (_ext, _config, browser) => fetchBpcUrl(browser),
  url: (ext) => fetchUrlSource(ext),
  'github-releases': fetchGithubReleaseUrl,
} satisfies Record<ExtensionSource, SourceFetcher>;

export async function fetchExtensionUrl(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
  version?: string,
): Promise<FetchUrlResult> {
  if (!supportsSource(browser, ext.source)) {
    return {
      error: `Source '${ext.source}' is not supported for ${browser} browser`,
    };
  }

  return sourceFetchers[ext.source](ext, config, browser, version);
}
