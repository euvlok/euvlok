import { join } from 'pathe';
import { z } from 'zod';

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

const RebaseStateSchema = z.object({
  originalBranch: z
    .string()
    .default('HEAD')
    .catch('HEAD')
    .transform((branch) => branch || 'HEAD'),
  originalHadStaged: z.boolean().default(false).catch(false),
  originalStagedFiles: z.string().default('').catch(''),
  stagedDiffPath: z.string().default('').catch(''),
  unstagedDiffPath: z.string().default('').catch(''),
  jjWasPresent: z.boolean().default(false).catch(false),
  timestamp: z
    .number()
    .default(0)
    .catch(0)
    .transform((timestamp) => Number(timestamp) || 0),
});

export function getStateFilePath(repoRoot: string): string {
  return join(repoRoot, STATE_MARKER);
}

export async function loadState(repoRoot: string): Promise<RebaseState | null> {
  const path = getStateFilePath(repoRoot);
  if (!(await Bun.file(path).exists())) return null;

  const content = await Bun.file(path).text();
  if (!content.trim()) return null;

  return RebaseStateSchema.parse(JSON.parse(content));
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
