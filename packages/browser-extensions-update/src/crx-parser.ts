import crx from 'crx-util';
import { unzipSync } from 'fflate';
import { z } from 'zod';

const CRX_MAGIC = new Uint8Array([0x43, 0x72, 0x32, 0x34]); // "Cr24"

type ManifestInfo = {
  version: string;
  permissions: string[];
  addonId?: string;
};

const stringArraySchema = z.array(z.string()).optional().catch(undefined);

const geckoSchema = z
  .object({
    id: z.string().optional(),
  })
  .optional();

const manifestSchema = z.looseObject({
  version: z.string().optional(),
  version_name: z.string().optional(),
  permissions: stringArraySchema,
  optional_permissions: stringArraySchema,
  host_permissions: stringArraySchema,
  browser_specific_settings: z
    .object({
      gecko: geckoSchema,
    })
    .optional(),
  applications: z
    .object({
      gecko: geckoSchema,
    })
    .optional(),
});

function isCrx(data: Uint8Array): boolean {
  return data.length >= CRX_MAGIC.length && CRX_MAGIC.every((byte, index) => data[index] === byte);
}

function hostPermissions(manifest: z.infer<typeof manifestSchema>): string[] {
  if (manifest.host_permissions) return manifest.host_permissions;
  return (manifest.optional_permissions ?? []).filter(isHostPermission);
}

function isHostPermission(permission: string): boolean {
  return permission.includes('/') || permission.includes('*');
}

function geckoAddonId(manifest: z.infer<typeof manifestSchema>): string | undefined {
  return manifest.browser_specific_settings?.gecko?.id ?? manifest.applications?.gecko?.id;
}

export async function extractManifestInfo(path: string): Promise<ManifestInfo> {
  const data = new Uint8Array(await Bun.file(path).arrayBuffer());
  const zip = isCrx(data) ? getZipContents(data) : data;

  const raw = unzipSync(zip)['manifest.json'];
  if (!raw) throw new Error('manifest.json not found in extension archive');

  const manifest = manifestSchema.parse(JSON.parse(new TextDecoder().decode(raw)));

  const version = manifest.version ?? manifest.version_name;
  if (!version) throw new Error('Could not extract version from manifest');

  const perms = [...(manifest.permissions ?? []), ...hostPermissions(manifest)];

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
