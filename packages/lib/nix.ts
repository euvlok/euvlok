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

export async function nixHashToSri(hexHash: string): Promise<string> {
  const result = await execSafe(['nix', 'hash', 'to-sri', '--type', 'sha256', hexHash]);
  if (result.exitCode !== 0) {
    throw new Error(`Failed to convert nix hash to SRI: ${result.stderr}`);
  }

  return result.stdout;
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
