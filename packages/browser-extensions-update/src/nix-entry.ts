import { escapeNixString } from '@euvlok/core';
import type { BrowserType, Extension } from './types';

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

function firefox(id: string, url: string, hash: string, version: string, perms: string[] | undefined, addon: string) {
  const meta =
    perms && perms.length > 0
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

export function generateExtensionNixEntry(
  ext: Extension,
  url: string,
  hash: string,
  version: string,
  perms: string[] | undefined,
  browser: BrowserType,
  addon?: string,
) {
  const id = escapeNixString(ext.id);
  const escapeNix = (s: string) => escapeNixString(s);

  if (browser === 'chromium') return chromium(id, escapeNix(url), escapeNix(hash), escapeNix(version));
  return firefox(id, escapeNix(url), escapeNix(hash), escapeNix(version), perms, escapeNix(addon ?? ext.id));
}
