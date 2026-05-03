import { execSafe } from './shell';

/**
 * Escape special characters for Nix string literals: backslash, double quote, dollar sign.
 */
export function escapeNixString(s: string): string {
  return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\$/g, '\\$');
}

export async function nixEvalRaw(expr: string): Promise<string | null> {
  const result = await execSafe(['nix', 'eval', '--impure', '--raw', '--expr', expr]);
  return result.exitCode === 0 ? result.stdout : null;
}

export async function nixEvalJson(expr: string): Promise<unknown | null> {
  const result = await execSafe(['nix', 'eval', '--json', '--impure', '--expr', expr]);
  if (result.exitCode !== 0 || !result.stdout) {
    return null;
  }

  return JSON.parse(result.stdout);
}

export async function sha256SriFromFile(filePath: string): Promise<string> {
  const hasher = new Bun.CryptoHasher('sha256');
  hasher.update(new Uint8Array(await Bun.file(filePath).arrayBuffer()));
  return `sha256-${hasher.digest('base64')}`;
}

/**
 * Validate a Nix file by parsing it with nix-instantiate.
 */
export async function validateNixFile(filePath: string): Promise<void> {
  const result = await execSafe(['nix-instantiate', '--parse', filePath]);
  if (result.exitCode !== 0) {
    throw new Error(`Generated nix file is invalid: ${filePath}`);
  }
}
