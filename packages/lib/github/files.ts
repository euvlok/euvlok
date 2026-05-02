import { create as createGlob } from '@actions/glob';

export { withTempFile } from '../files';

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
