import { escapeNixString } from '@euvlok/shared';
import type { Extension, BrowserType } from './types';

function chromium(id: string, url: string, hash: string, version: string) {
  return `  {
    id = "${id}";
    crxPath = pkgs.fetchurl {
      url = "${url}";
      name = "${id}.crx";
      hash = "${hash}";
    };
    version = "${version}";
  }`;
}

function firefox(
  id: string,
  url: string,
  hash: string,
  version: string,
  perms: string[] | undefined,
  addon: string,
) {
  const meta = perms && perms.length > 0
    ? `platforms = platforms.all;
      mozPermissions = [
${perms.map((p) => `        "${escapeNixString(p)}"`).join('\n')}
      ];`
    : 'platforms = platforms.all;';

  return `  {
    pname = "${id}";
    version = "${version}";
    addonId = "${addon}";
    url = "${url}";
    sha256 = "${hash}";
    meta = with lib; {
      ${meta}
    };
  }`;
}

export function generateNixEntry(
  ext: Extension,
  url: string,
  hash: string,
  version: string,
  perms: string[] | undefined,
  browser: BrowserType,
  addon?: string,
) {
  const id = escapeNixString(ext.id);
  const safe = (s: string) => escapeNixString(s);

  if (browser === 'chromium') return chromium(id, safe(url), safe(hash), safe(version));
  return firefox(id, safe(url), safe(hash), safe(version), perms, safe(addon ?? ext.id));
}
