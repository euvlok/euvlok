export interface ExecResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

/**
 * Execute a shell command and return the trimmed stdout.
 * Throws on non-zero exit code.
 */
export async function exec(cmd: string[], opts?: { cwd?: string }): Promise<string> {
  const result = Bun.spawn(cmd, {
    cwd: opts?.cwd,
    stdout: 'pipe',
    stderr: 'pipe',
  });

  const exitCode = await result.exited;
  const stdout = await new Response(result.stdout).text();
  const stderr = await new Response(result.stderr).text();

  if (exitCode !== 0) {
    throw new Error(`Command failed (exit ${exitCode}): ${cmd.join(' ')}\n${stderr}`);
  }

  return stdout.trim();
}

/**
 * Execute a shell command and return the result without throwing on failure.
 */
export async function execSafe(cmd: string[], opts?: { cwd?: string }): Promise<ExecResult> {
  const result = Bun.spawn(cmd, {
    cwd: opts?.cwd,
    stdout: 'pipe',
    stderr: 'pipe',
  });

  const exitCode = await result.exited;
  const stdout = await new Response(result.stdout).text();
  const stderr = await new Response(result.stderr).text();

  return { stdout: stdout.trim(), stderr: stderr.trim(), exitCode };
}
