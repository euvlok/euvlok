export interface RebaseContext {
  repoRoot: string;
  dryRun: boolean;
  autoRebase: boolean;
  backupDir: string;
  jjWasPresent: boolean;
  cleanupNeeded: boolean;
  originalBranch: string;
  originalHadStaged: boolean;
  originalStagedFiles: string;
  stagedDiffPath: string;
  unstagedDiffPath: string;
  backupFile: string;
}

export function createContext(
  repoRoot: string,
  dryRun: boolean,
  autoRebase: boolean,
  backupDir: string,
): RebaseContext {
  return {
    repoRoot,
    dryRun,
    autoRebase,
    backupDir,
    jjWasPresent: false,
    cleanupNeeded: false,
    originalBranch: '',
    originalHadStaged: false,
    originalStagedFiles: '',
    stagedDiffPath: '',
    unstagedDiffPath: '',
    backupFile: '',
  };
}
