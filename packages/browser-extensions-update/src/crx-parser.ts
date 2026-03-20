import { unzipSync } from 'fflate';

const CRX_MAGIC = new Uint8Array([0x43, 0x72, 0x32, 0x34]); // "Cr24"
const ZIP_MAGIC = new Uint8Array([0x50, 0x4b, 0x03, 0x04]); // PK\x03\x04

interface ManifestInfo {
  version: string;
  permissions: string[];
  addonId?: string;
}

function findZipOffset(data: Uint8Array): number {
  for (let i = 0; i < data.length - 3; i++) {
    if (
      data[i] === ZIP_MAGIC[0] &&
      data[i + 1] === ZIP_MAGIC[1] &&
      data[i + 2] === ZIP_MAGIC[2] &&
      data[i + 3] === ZIP_MAGIC[3]
    ) {
      return i;
    }
  }
  return -1;
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

  const offset = isCrx(data) ? findZipOffset(data) : 0;
  if (offset < 0) throw new Error('Could not find ZIP archive within CRX file');
  const zip = offset > 0 ? data.slice(offset) : data;

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
