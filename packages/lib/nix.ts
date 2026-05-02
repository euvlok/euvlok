import { execSafe } from './shell';

/**
 * Escape special characters for Nix string literals: backslash, double quote, dollar sign.
 */
export function escapeNixString(s: string): string {
  return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\$/g, '\\$');
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
