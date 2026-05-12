export interface CommandResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export interface CommandOptions {
  cwd?: string;
  env?: Record<string, string | undefined>;
  input?: string;
  inheritOutput?: boolean;
  trimOutput?: boolean;
}

/**
 * Run a command without invoking a shell and return stdout.
 * Throws on non-zero exit code.
 */
export async function runCommand(cmd: string[], opts?: CommandOptions): Promise<string> {
  const result = await runCommandResult(cmd, opts);

  if (result.exitCode !== 0) {
    throw new Error(`Command failed (exit ${result.exitCode}): ${cmd.join(' ')}\n${result.stderr}`);
  }

  return result.stdout;
}

/**
 * Run a command without invoking a shell and return its exit result.
 */
export async function runCommandResult(cmd: string[], opts?: CommandOptions): Promise<CommandResult> {
  if (cmd.length === 0) {
    throw new Error('Cannot execute an empty command.');
  }

  let proc: Bun.Subprocess<'pipe' | 'ignore', 'pipe', 'pipe'>;
  try {
    proc = Bun.spawn(cmd, {
      cwd: opts?.cwd,
      env: buildEnv(opts?.env),
      stdin: opts?.input === undefined ? 'ignore' : 'pipe',
      stdout: 'pipe',
      stderr: 'pipe',
    });
  } catch (e: unknown) {
    if (e instanceof Error && 'code' in e && e.code === 'ENOENT') {
      return {
        stdout: '',
        stderr: e.message,
        exitCode: 127,
      };
    }

    throw e;
  }

  if (opts?.input !== undefined) {
    if (proc.stdin && typeof proc.stdin !== 'number') {
      proc.stdin.write(opts.input);
      proc.stdin.end();
    }
  }

  const [stdout, stderr, exitCode] = await Promise.all([
    readOutput(proc.stdout, opts?.inheritOutput ? process.stdout : undefined),
    readOutput(proc.stderr, opts?.inheritOutput ? process.stderr : undefined),
    proc.exited,
  ]);

  const trim = opts?.trimOutput ?? true;
  return {
    stdout: trim ? stdout.trim() : stdout,
    stderr: trim ? stderr.trim() : stderr,
    exitCode,
  };
}

/**
 * Read an entire process output stream, optionally mirroring chunks as they arrive.
 */
async function readOutput(stream: ReadableStream<Uint8Array>, mirror?: NodeJS.WriteStream): Promise<string> {
  const chunks: Uint8Array[] = [];

  for await (const chunk of stream) {
    chunks.push(chunk);
    mirror?.write(chunk);
  }

  return Buffer.concat(chunks).toString();
}

/**
 * Merge process.env with overrides, deleting keys set to undefined.
 */
function buildEnv(overrides?: Record<string, string | undefined>): Record<string, string> {
  return Object.entries(overrides ?? {}).reduce(
    (env, [key, value]) => {
      if (value === undefined) {
        delete env[key];
        return env;
      }

      env[key] = value;
      return env;
    },
    Object.fromEntries(
      Object.entries(process.env).filter((entry): entry is [string, string] => entry[1] !== undefined),
    ),
  );
}
