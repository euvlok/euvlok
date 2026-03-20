import type { FetchUrlResult } from '../types';

export async function fetchChromeStoreUrl(
  id: string,
  version?: string,
): Promise<FetchUrlResult> {
  const url = new URL('https://clients2.google.com/service/update2/crx');
  url.searchParams.set('response', 'redirect');
  url.searchParams.set('acceptformat', 'crx2,crx3');
  url.searchParams.set('prodversion', version ?? '143');
  url.searchParams.set('x', `id=${id}&installsource=ondemand&uc`);

  const response = await fetch(url.toString(), { redirect: 'manual' });

  if (response.status === 302 || response.status === 301) {
    return { url: response.headers.get('location') ?? undefined };
  }

  return { error: `Chrome Store returned status ${response.status}` };
}
