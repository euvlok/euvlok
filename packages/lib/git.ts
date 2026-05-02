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
  return lines(await simpleGit(root).raw(['diff', '--cached', '--name-only']));
}
