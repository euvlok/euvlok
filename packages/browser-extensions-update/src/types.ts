import { assertNever } from '@euvlok/core';
import { z } from 'zod';

export type BrowserType = 'chromium' | 'firefox';

export type ExtensionSource = 'chrome-store' | 'amo' | 'bpc' | 'url' | 'github-releases';

export const BrowserTypeSchema = z.enum(['chromium', 'firefox']);

const ExtensionSourceSchema = z.enum(['chrome-store', 'amo', 'bpc', 'url', 'github-releases']);

const optionalString = z.string().nullish().transform(valueOrUndefined);
const optionalUrl = z.url().nullish().transform(valueOrUndefined);

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

const NixInputExtensionSchema = z.object({
  id: optionalString,
  name: optionalString,
  source: z.preprocess((value) => value ?? 'chrome-store', ExtensionSourceSchema),
  url: optionalUrl,
  condition: optionalString,
  owner: optionalString,
  repo: optionalString,
  pattern: optionalString,
  version: optionalString,
});

export const NixInputFileSchema = z.object({
  browser: BrowserTypeSchema,
  extensions: z.array(NixInputExtensionSchema),
  config: z
    .object({
      sources: z
        .object({
          'github-releases': z
            .object({
              owner: optionalString,
              repo: optionalString,
              pattern: optionalString,
            })
            .optional(),
        })
        .optional(),
    })
    .optional(),
});

export type NixInputFile = z.infer<typeof NixInputFileSchema>;

export const AmoAddonSchema = z.object({
  current_version: z
    .object({
      file: z
        .object({
          url: z.url().optional(),
        })
        .optional(),
    })
    .optional(),
  guid: optionalString,
});

export type AmoAddon = z.infer<typeof AmoAddonSchema>;

function valueOrUndefined<T>(value: T | null | undefined): T | undefined {
  return value ?? undefined;
}

export interface ExtensionDownloadUrlResult {
  url?: string;
  error?: string;
  addonId?: string;
}

export function getBrowserDownloadFileExtension(browser: BrowserType): string {
  return browser === 'chromium' ? 'crx' : 'xpi';
}

export function isExtensionSourceSupported(browser: BrowserType, source: ExtensionSource): boolean {
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
      return assertNever(source);
  }
}
