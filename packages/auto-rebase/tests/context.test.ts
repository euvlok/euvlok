import { describe, test, expect } from 'bun:test';
import { createContext } from '../src/context';

describe('createContext', () => {
  test('returns correct defaults', () => {
    const ctx = createContext('/repo', false, true, '/tmp');
    expect(ctx.repoRoot).toBe('/repo');
    expect(ctx.dryRun).toBe(false);
    expect(ctx.autoRebase).toBe(true);
    expect(ctx.backupDir).toBe('/tmp');
    expect(ctx.jjWasPresent).toBe(false);
    expect(ctx.cleanupNeeded).toBe(false);
    expect(ctx.originalBranch).toBe('');
    expect(ctx.originalHadStaged).toBe(false);
    expect(ctx.originalStagedFiles).toBe('');
    expect(ctx.stagedDiffPath).toBe('');
    expect(ctx.unstagedDiffPath).toBe('');
    expect(ctx.backupFile).toBe('');
  });

  test('constructor args passed through', () => {
    const ctx = createContext('/my/repo', true, false, '/backups');
    expect(ctx.repoRoot).toBe('/my/repo');
    expect(ctx.dryRun).toBe(true);
    expect(ctx.autoRebase).toBe(false);
    expect(ctx.backupDir).toBe('/backups');
  });
});
