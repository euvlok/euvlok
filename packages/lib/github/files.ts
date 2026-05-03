import { stat } from 'node:fs/promises';
import { join } from 'node:path';

export { withTempFile } from '../files';

export async function walkFiles(
  root: string,
  predicate: (path: string) => boolean,
): Promise<string[]> {
  if (!(await directoryExists(root))) {
    return [];
  }

  const paths = await Array.fromAsync(
    new Bun.Glob('**/*').scan({
      cwd: root,
      dot: true,
      followSymlinks: false,
      onlyFiles: true,
    }),
  );

  return paths
    .map((path) => join(root, path))
    .filter((path) => predicate(path))
    .sort((a, b) => a.localeCompare(b));
}

async function directoryExists(path: string): Promise<boolean> {
  return stat(path)
    .then((stats) => stats.isDirectory())
    .catch(() => false);
}
