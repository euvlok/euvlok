import crx from 'crx-util';
import { unzipSync } from 'fflate';

const CRX_MAGIC = new Uint8Array([0x43, 0x72, 0x32, 0x34]); // "Cr24"

interface ManifestInfo {
  version: string;
  permissions: string[];
  addonId?: string;
}

function isCrx(data: Uint8Array): boolean {
  return (
    data.length >= 4 &&
    data[0] === CRX_MAGIC[0] &&
    data[1] === CRX_MAGIC[1] &&
    data[2] === CRX_MAGIC[2] &&
    data[3] === CRX_MAGIC[3]
  );
}

const strings = (arr: unknown) =>
  Array.isArray(arr) ? arr.filter((p): p is string => typeof p === 'string') : [];

export async function extractManifestInfo(path: string): Promise<ManifestInfo> {
  const data = new Uint8Array(await Bun.file(path).arrayBuffer());
  const zip = isCrx(data) ? getZipContents(data) : data;

  const raw = unzipSync(zip)['manifest.json'];
  if (!raw) throw new Error('manifest.json not found in extension archive');

  const manifest = JSON.parse(new TextDecoder().decode(raw));

  const version = manifest.version ?? manifest.version_name;
  if (!version) throw new Error('Could not extract version from manifest');

  const perms = [
    ...strings(manifest.permissions),
    ...(Array.isArray(manifest.host_permissions)
      ? strings(manifest.host_permissions)
      : strings(manifest.optional_permissions).filter((p) => p.includes('/') || p.includes('*'))),
  ];

  const gecko = manifest.browser_specific_settings?.gecko ?? manifest.applications?.gecko;
  return { version, permissions: perms, addonId: gecko?.id };
}

function getZipContents(data: Uint8Array): Buffer {
  const log = console.log;
  try {
    console.log = () => undefined;
    return crx.parser.getZipContents(Buffer.from(data));
  } finally {
    console.log = log;
  }
}
