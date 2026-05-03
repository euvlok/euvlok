import type { Extension, ExtensionDownloadUrlResult } from '../types';

export function resolveConfiguredDownloadUrl(ext: Extension): ExtensionDownloadUrlResult {
  if (!ext.url) {
    return {
      error: `Extension '${ext.id}' has source 'url' but no 'url' field specified`,
    };
  }
  return { url: ext.url };
}
