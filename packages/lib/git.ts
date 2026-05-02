import { simpleGit } from 'simple-git';

function lines(stdout: string): string[] {
  return stdout
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
}

export async function addGitPaths(paths: string | string[], root?: string): Promise<void> {
  const items = Array.isArray(paths) ? paths : [paths];
  if (items.length === 0) return;
  await simpleGit(root).add(items);
}

export async function listStagedFiles(root?: string): Promise<string[]> {
  return lines(await simpleGit(root).diff(['--cached', '--name-only']));
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
