import crx from 'crx-util';
import { unzipSync } from 'fflate';

const CRX_MAGIC = new Uint8Array([0x43, 0x72, 0x32, 0x34]); // "Cr24"

type ManifestInfo = {
  version: string;
  permissions: string[];
  addonId?: string;
};

function isCrx(data: Uint8Array): boolean {
  return data.length >= CRX_MAGIC.length && CRX_MAGIC.every((byte, index) => data[index] === byte);
}

const strings = (arr: unknown) =>
  Array.isArray(arr) ? arr.filter((p): p is string => typeof p === 'string') : [];

function hostPermissions(manifest: Record<string, unknown>): string[] {
  if (Array.isArray(manifest.host_permissions)) return strings(manifest.host_permissions);
  return strings(manifest.optional_permissions).filter(isHostPermission);
}

function isHostPermission(permission: string): boolean {
  return permission.includes('/') || permission.includes('*');
}

function geckoAddonId(manifest: Record<string, unknown>): string | undefined {
  const browserSettings = manifest.browser_specific_settings;
  const applications = manifest.applications;
  const gecko = readRecord(browserSettings)?.gecko ?? readRecord(applications)?.gecko;
  return readRecord(gecko)?.id as string | undefined;
}

function readRecord(value: unknown): Record<string, unknown> | undefined {
  return typeof value === 'object' && value !== null
    ? (value as Record<string, unknown>)
    : undefined;
}

export async function extractManifestInfo(path: string): Promise<ManifestInfo> {
  const data = new Uint8Array(await Bun.file(path).arrayBuffer());
  const zip = isCrx(data) ? getZipContents(data) : data;

  const raw = unzipSync(zip)['manifest.json'];
  if (!raw) throw new Error('manifest.json not found in extension archive');

  const manifest = JSON.parse(new TextDecoder().decode(raw));

  const version = manifest.version ?? manifest.version_name;
  if (!version) throw new Error('Could not extract version from manifest');

  const perms = [...strings(manifest.permissions), ...hostPermissions(manifest)];

  return { version, permissions: perms, addonId: geckoAddonId(manifest) };
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
