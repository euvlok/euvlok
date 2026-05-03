import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { MaybePromise } from './utils';

/**
 * Create a temporary directory with the given prefix, pass it to a callback, then remove it.
 */
export async function withTempDir<T>(
  prefix: string,
  callback: (dir: string) => MaybePromise<T>,
): Promise<T> {
  const dir = await mkdtemp(join(tmpdir(), prefix));

  try {
    return await callback(dir);
  } finally {
    await removeTempDir(dir);
  }
}

/**
 * Create a temporary file path, pass it to a callback, then remove its directory.
 */
export async function withTempFilePath<T>(
  suffix: string,
  callback: (path: string) => MaybePromise<T>,
): Promise<T> {
  return withTempDir('euvlok-', (dir) => callback(join(dir, `content.${suffix}`)));
}

/**
 * Create a temporary file with content, pass its path to a callback, then clean it up.
 */
export async function withTempFile<T>(
  content: string,
  suffix: string,
  callback: (path: string) => MaybePromise<T>,
): Promise<T> {
  return withTempFilePath(suffix, async (path) => {
    await Bun.write(path, content);
    return callback(path);
  });
}

/**
 * Download a URL to a local file path.
 */
export async function downloadToFile(url: string, path: string): Promise<void> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download ${url}: HTTP ${response.status}`);
  }

  await Bun.write(path, new Uint8Array(await response.arrayBuffer()));
}

/**
 * Remove a temporary directory and ignore missing paths.
 */
async function removeTempDir(path: string): Promise<void> {
  await rm(path, { recursive: true, force: true });
}
