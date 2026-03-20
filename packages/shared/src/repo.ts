import { dirname, join } from 'pathe';

/**
 * Find the repository root by walking up from the current directory,
 * looking for flake.nix or .git directory.
 */
export async function findRepoRoot(startDir?: string): Promise<string | null> {
  let current = startDir ?? process.cwd();

  while (current !== '/') {
    if (
      (await Bun.file(join(current, 'flake.nix')).exists()) ||
      (await Bun.file(join(current, '.git', 'HEAD')).exists())
    ) {
      return current;
    }
    current = dirname(current);
  }

  return null;
}

/**
 * Check if a directory is a git repository.
 */
export async function isGitRepo(dir: string): Promise<boolean> {
  return Bun.file(join(dir, '.git', 'HEAD')).exists();
}

/**
 * Check if a directory is the euvlok repository.
 */
export async function isEuvlokRepo(dir: string): Promise<boolean> {
  return Bun.file(join(dir, '.euvlok')).exists();
}
