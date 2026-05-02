import { exec, logger } from '@euvlok/shared';
import type {
  BrowserType,
  Extension,
  ExtensionSource,
  GithubReleaseConfig,
  NixInputFile,
} from './types';

function parseBrowser(path: string, browser: unknown): BrowserType {
  if (browser === 'chromium' || browser === 'firefox') return browser;
  throw new Error(
    `Invalid or missing 'browser' field in ${path}. Must be 'chromium' or 'firefox'.`,
  );
}

function githubReleaseConfig(input: NixInputFile): GithubReleaseConfig {
  const source = input.config?.sources?.['github-releases'];
  return {
    owner: source?.owner,
    repo: source?.repo,
    pattern: source?.pattern,
  };
}

function hasExtensionId(extension: NixInputFile['extensions'][number]) {
  if (extension.id) return true;
  logger.warn("Extension missing 'id' field, skipping");
  return false;
}

function valueOrUndefined<T>(value: T | null | undefined): T | undefined {
  return value ?? undefined;
}

function toExtension(e: NixInputFile['extensions'][number] & { id: string }): Extension {
  return {
    id: e.id,
    name: valueOrUndefined(e.name),
    source: (e.source || 'chrome-store') as ExtensionSource,
    url: valueOrUndefined(e.url),
    condition: valueOrUndefined(e.condition),
    owner: valueOrUndefined(e.owner),
    repo: valueOrUndefined(e.repo),
    pattern: valueOrUndefined(e.pattern),
    version: valueOrUndefined(e.version),
  };
}

export async function parseNixInput(path: string) {
  const json = await exec(['nix', 'eval', '--json', '--file', path]);
  const input: NixInputFile = JSON.parse(json);

  const browser = parseBrowser(path, input.browser);
  const config = githubReleaseConfig(input);

  const extensions: Extension[] = input.extensions
    .filter((e): e is typeof e & { id: string } => hasExtensionId(e))
    .map(toExtension);

  const conditional = extensions.some((e) => e.condition);
  return { extensions, config, conditional, browser };
}
