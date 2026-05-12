import { z } from 'zod';
import type { BrowserType } from './types';

export type ExtensionSummary = {
  id: string;
  version: string;
  key: string;
  hash: string;
};

const chromiumExtensionSchema = z.object({
  id: z.string(),
  version: z.string(),
  crxPath: z.object({
    url: z.url(),
    hash: z.string(),
  }),
});

const firefoxExtensionSchema = z.object({
  name: z.string(),
  version: z.string(),
  url: z.url(),
  sha256: z.string(),
});

export function summarizeExtension(entry: unknown, browserType: BrowserType): ExtensionSummary | null {
  return browserType === 'chromium' ? summarizeChromiumExtension(entry) : summarizeFirefoxExtension(entry);
}

function summarizeChromiumExtension(entry: unknown): ExtensionSummary | null {
  const parsed = chromiumExtensionSchema.safeParse(entry);
  if (!parsed.success) return null;

  return buildExtensionSummary({
    id: parsed.data.id,
    version: parsed.data.version,
    url: parsed.data.crxPath.url,
    hash: parsed.data.crxPath.hash,
  });
}

function summarizeFirefoxExtension(entry: unknown): ExtensionSummary | null {
  const parsed = firefoxExtensionSchema.safeParse(entry);
  if (!parsed.success) return null;

  return buildExtensionSummary({
    id: parsed.data.name,
    version: parsed.data.version,
    url: parsed.data.url,
    hash: parsed.data.sha256,
  });
}

function buildExtensionSummary(input: {
  id: string;
  version: string;
  url: string;
  hash: string;
}): ExtensionSummary | null {
  if (!input.id || !input.version || !input.url) return null;

  return {
    id: input.id,
    version: input.version,
    key: `${input.id}|${input.version}|${input.url}`,
    hash: input.hash,
  };
}

export function formatUpdatedExtension(oldEntry: ExtensionSummary | undefined, newEntry: ExtensionSummary): string[] {
  if (!oldEntry) {
    return [];
  }

  if (oldEntry.version !== newEntry.version) {
    return [`${newEntry.id}|${oldEntry.version}|${newEntry.version}`];
  }

  return oldEntry.hash !== newEntry.hash
    ? [`${newEntry.id}|${oldEntry.version}|${newEntry.version} (hash changed)`]
    : [];
}
