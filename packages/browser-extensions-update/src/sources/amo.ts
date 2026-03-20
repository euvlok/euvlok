import type { AmoAddon, FetchUrlResult } from '../types';

export async function fetchAmoUrlAndGuid(slug: string): Promise<FetchUrlResult> {
  const response = await fetch(
    `https://addons.mozilla.org/api/v5/addons/addon/${slug}/`,
    { headers: { 'User-Agent': 'BrowserExtensionsUpdater' } },
  ).catch(() => null);

  if (!response?.ok) {
    return { error: `AMO API returned status ${response?.status ?? 'network error'}` };
  }

  const addon: AmoAddon = await response.json();
  return {
    url: addon.current_version?.file?.url,
    addonId: addon.guid ?? undefined,
  };
}
