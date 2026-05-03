import { simpleGit } from 'simple-git';
import { asArray, type MaybeArray, nonEmptyLines } from './utils';

export async function addGitPaths(paths: MaybeArray<string>, root?: string): Promise<void> {
  const items = asArray(paths);
  if (items.length === 0) return;
  await simpleGit(root).add(items);
}

export async function listStagedFiles(root?: string): Promise<string[]> {
  return nonEmptyLines(await simpleGit(root).diff(['--cached', '--name-only']));
}

export async function readGitBlob(ref: string, path: string, root?: string): Promise<string> {
  return simpleGit(root)
    .show(`${ref}:${path}`)
    .catch(() => '');
}

export async function readGitIndex(path: string, root?: string): Promise<string> {
  return simpleGit(root)
    .show(`:${path}`)
    .catch(() => '');
}

export async function stagedShortstat(root?: string): Promise<string> {
  return simpleGit(root).diff(['--staged', '--shortstat']);
}
