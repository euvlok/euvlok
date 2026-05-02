import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { create as createGlob } from '@actions/glob';
import { rmRF } from '@actions/io';

async function writeTempFile(content: string, suffix = 'tmp'): Promise<string> {
  const dir = await mkdtemp(join(tmpdir(), 'euvlok-gh-'));
  const path = join(dir, `content.${suffix}`);
  await Bun.write(path, content);
  return path;
}

export async function withTempFile<T>(
  content: string,
  suffix: string,
  callback: (path: string) => Promise<T>,
): Promise<T> {
  const path = await writeTempFile(content, suffix);
  try {
    return await callback(path);
  } finally {
    await removeTempPath(path);
  }
}

async function removeTempPath(path: string): Promise<void> {
  await rmRF(dirname(path));
}

export async function walkFiles(
  root: string,
  predicate: (path: string) => boolean,
): Promise<string[]> {
  if (!(await Bun.file(root).exists())) {
    return [];
  }

  const globber = await createGlob(`${root.replace(/\/$/, '')}/**/*`, {
    followSymbolicLinks: false,
    implicitDescendants: false,
  });
  const paths = await globber.glob();
  return paths.filter((path) => predicate(path)).sort((a, b) => a.localeCompare(b));
}
