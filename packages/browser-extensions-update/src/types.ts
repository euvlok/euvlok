export type BrowserType = 'chromium' | 'firefox';

export type ExtensionSource = 'chrome-store' | 'amo' | 'bpc' | 'url' | 'github-releases';

export interface Extension {
  id: string;
  name?: string;
  source: ExtensionSource;
  url?: string;
  condition?: string;
  owner?: string;
  repo?: string;
  pattern?: string;
  version?: string;
}

export interface GithubReleaseConfig {
  owner?: string;
  repo?: string;
  pattern?: string;
}

export interface ExtensionResult {
  extension: Extension;
  error?: string;
  nixEntry?: string;
  version?: string;
}

export interface NixInputFile {
  browser?: string;
  extensions: NixInputExtension[];
  config?: NixInputConfig;
}

export interface NixInputExtension {
  id?: string;
  name?: string;
  source?: string;
  url?: string;
  condition?: string;
  owner?: string;
  repo?: string;
  pattern?: string;
  version?: string;
}

export interface NixInputConfig {
  sources?: {
    'github-releases'?: {
      owner?: string;
      repo?: string;
      pattern?: string;
    };
  };
}

export interface GitHubRelease {
  tag_name?: string;
  name?: string;
}

export interface AmoAddon {
  current_version?: {
    file?: {
      url: string;
    };
  };
  guid?: string;
}

export interface FetchUrlResult {
  url?: string;
  error?: string;
  addonId?: string;
}

export function getFileExtension(browser: BrowserType): string {
  return browser === 'chromium' ? 'crx' : 'xpi';
}

export function supportsSource(browser: BrowserType, source: ExtensionSource): boolean {
  switch (source) {
    case 'chrome-store':
      return browser === 'chromium';
    case 'amo':
      return browser === 'firefox';
    case 'bpc':
    case 'url':
    case 'github-releases':
      return true;
    default:
      return false;
  }
}
