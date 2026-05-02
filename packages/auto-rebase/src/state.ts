import { join } from 'pathe';

const STATE_MARKER = '.auto-rebase-state';

export interface RebaseState {
  originalBranch: string;
  originalHadStaged: boolean;
  originalStagedFiles: string;
  stagedDiffPath: string;
  unstagedDiffPath: string;
  jjWasPresent: boolean;
  timestamp: number;
}

export function getStateFilePath(repoRoot: string): string {
  return join(repoRoot, STATE_MARKER);
}

export async function loadState(repoRoot: string): Promise<RebaseState | null> {
  const path = getStateFilePath(repoRoot);
  if (!(await Bun.file(path).exists())) return null;

  const content = await Bun.file(path).text();
  if (!content.trim()) return null;

  const parsed = JSON.parse(content) as Partial<RebaseState>;
  const originalBranch = parsed.originalBranch || 'HEAD';
  const timestamp = Number(parsed.timestamp) || 0;

  return {
    originalBranch,
    originalHadStaged: parsed.originalHadStaged === true,
    originalStagedFiles: parsed.originalStagedFiles ?? '',
    stagedDiffPath: parsed.stagedDiffPath ?? '',
    unstagedDiffPath: parsed.unstagedDiffPath ?? '',
    jjWasPresent: parsed.jjWasPresent === true,
    timestamp,
  };
}

export async function saveState(repoRoot: string, state: RebaseState): Promise<void> {
  const path = getStateFilePath(repoRoot);
  await Bun.write(path, `${JSON.stringify(state, null, 2)}\n`);
}

export async function removeState(repoRoot: string): Promise<void> {
  await Bun.file(getStateFilePath(repoRoot))
    .delete()
    .catch(() => undefined);
}
