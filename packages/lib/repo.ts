import { dirname, join } from 'pathe';

/**
 * Find the repository root by walking up from the current directory,
 * looking for flake.nix or .git directory.
 */
export async function findRepoRoot(startDir?: string): Promise<string | null> {
  const current = startDir ?? process.cwd();
  if (current === '/') return null;

  if (
    (await Bun.file(join(current, 'flake.nix')).exists()) ||
    (await Bun.file(join(current, '.git', 'HEAD')).exists())
  ) {
    return current;
  }

  return findRepoRoot(dirname(current));
}

/**
 * Check if a directory is a git repository.
 */
export async function isGitRepo(dir: string): Promise<boolean> {
  return Bun.file(join(dir, '.git', 'HEAD')).exists();
}
