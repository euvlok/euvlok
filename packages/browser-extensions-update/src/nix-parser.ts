import { logger, exec } from '@euvlok/shared';
import type {
  BrowserType,
  Extension,
  ExtensionSource,
  GithubReleaseConfig,
  NixInputFile,
} from './types';

export async function parseNixInput(path: string) {
  const json = await exec(['nix', 'eval', '--json', '--file', path]);
  const input: NixInputFile = JSON.parse(json);

  if (!input.browser || (input.browser !== 'chromium' && input.browser !== 'firefox')) {
    throw new Error(
      `Invalid or missing 'browser' field in ${path}. Must be 'chromium' or 'firefox'.`,
    );
  }

  const browser: BrowserType = input.browser;

  const config: GithubReleaseConfig = {
    owner: input.config?.sources?.['github-releases']?.owner,
    repo: input.config?.sources?.['github-releases']?.repo,
    pattern: input.config?.sources?.['github-releases']?.pattern,
  };

  const extensions: Extension[] = input.extensions
    .filter((e) => {
      if (!e.id) logger.warn("Extension missing 'id' field, skipping");
      return !!e.id;
    })
    .map((e) => ({
      id: e.id!,
      name: e.name ?? undefined,
      source: (e.source ?? 'chrome-store') as ExtensionSource,
      url: e.url ?? undefined,
      condition: e.condition ?? undefined,
      owner: e.owner ?? undefined,
      repo: e.repo ?? undefined,
      pattern: e.pattern ?? undefined,
      version: e.version ?? undefined,
    }));

  const conditional = extensions.some((e) => e.condition);
  return { extensions, config, conditional, browser };
}
