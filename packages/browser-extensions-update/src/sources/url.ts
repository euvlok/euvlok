import type { Extension, FetchUrlResult } from '../types';

export function fetchUrlSource(ext: Extension): FetchUrlResult {
  if (!ext.url) {
    return {
      error: `Extension '${ext.id}' has source 'url' but no 'url' field specified`,
    };
  }
  return { url: ext.url };
}
