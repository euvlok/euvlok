import { $ } from 'bun';
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

  function value(key: string): string {
    const match = content.match(new RegExp(`^${key}="(.*)"$`, 'm'));
    return match ? match[1] : '';
  }

  function raw(key: string): string {
    const match = content.match(new RegExp(`^${key}=(.*)$`, 'm'));
    return match ? match[1] : '';
  }

  const originalBranch = value('ORIGINAL_BRANCH') || 'HEAD';
  const timestamp = parseInt(raw('TIMESTAMP')) || 0;

  // Validate basic sanity
  if (!originalBranch && !timestamp) return null;

  return {
    originalBranch,
    originalHadStaged: value('ORIGINAL_HAD_STAGED') === 'true',
    originalStagedFiles: value('ORIGINAL_STAGED_FILES'),
    stagedDiffPath: value('PATH_TO_STAGED_DIFF'),
    unstagedDiffPath: value('PATH_TO_UNSTAGED_DIFF'),
    jjWasPresent: value('JJ_WAS_PRESENT') === 'true',
    timestamp,
  };
}

export async function saveState(repoRoot: string, state: RebaseState): Promise<void> {
  const path = getStateFilePath(repoRoot);
  const content =
    [
      `ORIGINAL_BRANCH="${state.originalBranch}"`,
      `ORIGINAL_HAD_STAGED="${state.originalHadStaged}"`,
      `ORIGINAL_STAGED_FILES="${state.originalStagedFiles}"`,
      `PATH_TO_STAGED_DIFF="${state.stagedDiffPath}"`,
      `PATH_TO_UNSTAGED_DIFF="${state.unstagedDiffPath}"`,
      `JJ_WAS_PRESENT="${state.jjWasPresent}"`,
      `TIMESTAMP=${state.timestamp}`,
    ].join('\n') + '\n';

  await Bun.write(path, content);
}

export async function removeState(repoRoot: string): Promise<void> {
  await $`rm -f ${getStateFilePath(repoRoot)}`.quiet();
}
