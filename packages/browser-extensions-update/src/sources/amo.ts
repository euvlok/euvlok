import { type AmoAddon, AmoAddonSchema, type ExtensionDownloadUrlResult } from '../types';

async function fetchAddon(slug: string): Promise<Response | null> {
  return fetch(`https://addons.mozilla.org/api/v5/addons/addon/${slug}/`, {
    headers: { 'User-Agent': 'BrowserExtensionsUpdater' },
  }).catch(() => null);
}

function responseError(response: Response | null): ExtensionDownloadUrlResult | null {
  if (response?.ok) return null;
  return { error: `AMO API returned status ${response?.status ?? 'network error'}` };
}

function addonResult(addon: AmoAddon): ExtensionDownloadUrlResult {
  return {
    url: addon.current_version?.file?.url,
    addonId: addon.guid ?? undefined,
  };
}

export async function fetchAmoUrlAndGuid(slug: string): Promise<ExtensionDownloadUrlResult> {
  const response = await fetchAddon(slug);
  const error = responseError(response);
  if (error) return error;

  const addon: AmoAddon = AmoAddonSchema.parse(await response?.json());
  return addonResult(addon);
}
