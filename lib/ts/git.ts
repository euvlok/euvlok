import { simpleGit } from 'simple-git';
import { type MaybeArray, splitNonEmptyLines, toArray } from './utils';

/**
 * Stage one or more paths in a git repository.
 */
export async function addGitPaths(paths: MaybeArray<string>, root?: string): Promise<void> {
  const items = toArray(paths);
  if (items.length === 0) return;
  await simpleGit(root).add(items);
}

/**
 * List files currently staged in the git index.
 */
export async function listStagedFiles(root?: string): Promise<string[]> {
  return splitNonEmptyLines(await simpleGit(root).diff(['--cached', '--name-only']));
}

/**
 * Read a file from a git ref, returning an empty string when it does not exist.
 */
export async function readGitBlob(ref: string, path: string, root?: string): Promise<string> {
  return simpleGit(root)
    .show(`${ref}:${path}`)
    .catch(() => '');
}

/**
 * Read a file from the git index, returning an empty string when it is not staged.
 */
export async function readGitIndex(path: string, root?: string): Promise<string> {
  return simpleGit(root)
    .show(`:${path}`)
    .catch(() => '');
}

/**
 * Return git's shortstat summary for staged changes.
 */
export async function getStagedShortstat(root?: string): Promise<string> {
  return simpleGit(root).diff(['--staged', '--shortstat']);
}
