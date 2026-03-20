import type { Extension, GithubReleaseConfig, BrowserType, FetchUrlResult } from '../types';
import { supportsSource } from '../types';
import { fetchChromeStoreUrl } from './chrome-store';
import { fetchAmoUrlAndGuid } from './amo';
import { fetchBpcUrl } from './bpc';
import { fetchGithubReleaseUrl } from './github-releases';
import { fetchUrlSource } from './url';

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

  switch (ext.source) {
    case 'chrome-store':
      return fetchChromeStoreUrl(ext.id, version);
    case 'amo':
      return fetchAmoUrlAndGuid(ext.id);
    case 'bpc':
      return fetchBpcUrl(browser);
    case 'url':
      return fetchUrlSource(ext);
    case 'github-releases':
      return fetchGithubReleaseUrl(ext, config, browser);
    default:
      return { error: `Unknown source '${ext.source}'` };
  }
}
