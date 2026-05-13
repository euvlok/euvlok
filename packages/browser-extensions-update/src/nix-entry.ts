import { nixStringLiteral } from '@euvlok/core';
import type { BrowserType, Extension } from './types';

function chromium(id: string, url: string, hash: string, version: string) {
  return `  {
    id = ${nixStringLiteral(id)};
    crxPath = pkgs.fetchurl {
      url = ${nixStringLiteral(url)};
      name = ${nixStringLiteral(`${id}.crx`)};
      hash = ${nixStringLiteral(hash)};
    };
    version = ${nixStringLiteral(version)};
  }`;
}

function firefox(id: string, url: string, hash: string, version: string, perms: string[] | undefined, addon: string) {
  const meta =
    perms && perms.length > 0
      ? `platforms = platforms.all;
      mozPermissions = [
${perms.map((p) => `        ${nixStringLiteral(p)}`).join('\n')}
      ];`
      : 'platforms = platforms.all;';

  return `  {
    pname = ${nixStringLiteral(id)};
    version = ${nixStringLiteral(version)};
    addonId = ${nixStringLiteral(addon)};
    url = ${nixStringLiteral(url)};
    sha256 = ${nixStringLiteral(hash)};
    meta = with lib; {
      ${meta}
    };
  }`;
}

export function generateExtensionNixEntry(
  ext: Extension,
  url: string,
  hash: string,
  version: string,
  perms: string[] | undefined,
  browser: BrowserType,
  addon?: string,
) {
  if (browser === 'chromium') return chromium(ext.id, url, hash, version);
  return firefox(ext.id, url, hash, version, perms, addon ?? ext.id);
}
