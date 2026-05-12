import { simpleGit } from 'simple-git';
import type { BrowserType, ExtensionDownloadUrlResult } from '../types';

const BPC_REPO = 'https://gitflic.ru/project/magnolia1234/bpc_uploads.git';

export async function fetchBpcUrl(browser: BrowserType): Promise<ExtensionDownloadUrlResult> {
  const filename =
    browser === 'chromium' ? 'bypass-paywalls-chrome-clean-latest.crx' : 'bypass_paywalls_clean-latest.xpi';

  const output = await simpleGit().listRemote([BPC_REPO, 'HEAD']);
  const commit = output.split('\t')[0];

  if (!commit) {
    return { error: 'Failed to get latest commit for BPC' };
  }

  const url = new URL('https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw');
  url.searchParams.set('file', filename);
  url.searchParams.set('inline', 'false');
  url.searchParams.set('commit', commit);

  return { url: url.toString() };
}
