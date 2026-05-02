export { addGitPaths, listStagedFiles } from './git';
export { consola, logger } from './logger';
export { escapeNixString, validateNixFile } from './nix';
export { findRepoRoot, isGitRepo } from './repo';
export type { ExecResult } from './shell';
export { exec, execSafe } from './shell';
