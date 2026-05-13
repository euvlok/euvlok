import { runCommandResult } from './shell';

/**
 * Render a JavaScript string as a Nix double-quoted string literal.
 *
 * This mirrors nixpkgs' `lib.strings.escapeNixString`: JSON string escaping is
 * already valid for Nix double-quoted strings, with `$` additionally escaped to
 * avoid interpolation.
 */
export function nixStringLiteral(s: string): string {
  return JSON.stringify(s).replace(/\$/g, '\\$');
}

/**
 * Escape a string for embedding inside an existing Nix double-quoted string.
 */
export function escapeNixString(s: string): string {
  const literal = nixStringLiteral(s);
  return literal.slice(1, -1);
}

/**
 * Evaluate a Nix expression and return raw stdout, or null when evaluation fails.
 */
export async function evaluateNixRaw(expr: string): Promise<string | null> {
  const result = await runCommandResult(['nix', 'eval', '--impure', '--raw', '--expr', expr]);
  return result.exitCode === 0 ? result.stdout : null;
}

/**
 * Evaluate a Nix expression as JSON, returning null when evaluation fails or has no output.
 */
export async function evaluateNixJson(expr: string): Promise<unknown | null> {
  const result = await runCommandResult(['nix', 'eval', '--json', '--impure', '--expr', expr]);
  if (result.exitCode !== 0 || !result.stdout) {
    return null;
  }

  return JSON.parse(result.stdout);
}

/**
 * Compute a sha256 SRI hash for a local file.
 */
export async function computeFileSha256Sri(filePath: string): Promise<string> {
  const hasher = new Bun.CryptoHasher('sha256');
  hasher.update(new Uint8Array(await Bun.file(filePath).arrayBuffer()));
  return `sha256-${hasher.digest('base64')}`;
}

/**
 * Validate a Nix file by parsing it with nix-instantiate.
 */
export async function assertValidNixFile(filePath: string): Promise<void> {
  const result = await runCommandResult(['nix-instantiate', '--parse', filePath]);
  if (result.exitCode !== 0) {
    throw new Error(`Generated nix file is invalid: ${filePath}`);
  }
}
