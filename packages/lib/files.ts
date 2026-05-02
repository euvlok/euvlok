import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';

export async function withTempPath<T>(
  suffix: string,
  callback: (path: string) => Promise<T>,
): Promise<T> {
  const dir = await mkdtemp(join(tmpdir(), 'euvlok-'));
  const path = join(dir, `content.${suffix}`);

  return callback(path).finally(() => removeTempPath(path));
}

export async function withTempFile<T>(
  content: string,
  suffix: string,
  callback: (path: string) => Promise<T>,
): Promise<T> {
  return withTempPath(suffix, async (path) => {
    await Bun.write(path, content);
    return callback(path);
  });
}

async function removeTempPath(path: string): Promise<void> {
  await rm(dirname(path), { recursive: true, force: true });
}
