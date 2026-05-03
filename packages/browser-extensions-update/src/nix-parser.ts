import { logger, runCommand } from '@euvlok/core';
import type { BrowserType, Extension, GithubReleaseConfig, NixInputFile } from './types';
import { NixInputFileSchema } from './types';

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

function toExtension(e: NixInputFile['extensions'][number] & { id: string }): Extension {
  return {
    id: e.id,
    name: e.name,
    source: e.source,
    url: e.url,
    condition: e.condition,
    owner: e.owner,
    repo: e.repo,
    pattern: e.pattern,
    version: e.version,
  };
}

export async function parseNixExtensionInput(path: string) {
  const json = await runCommand(['nix', 'eval', '--json', '--file', path]);
  const input = NixInputFileSchema.parse(JSON.parse(json));

  const browser: BrowserType = input.browser;
  const config = githubReleaseConfig(input);

  const extensions: Extension[] = input.extensions
    .filter((e): e is typeof e & { id: string } => hasExtensionId(e))
    .map(toExtension);

  const conditional = extensions.some((e) => e.condition);
  return { extensions, config, conditional, browser };
}
