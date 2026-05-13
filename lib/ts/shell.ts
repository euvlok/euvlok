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

  const command = prepareCommand(opts);
  const proc = spawnCommand(cmd, command);
  if (isCommandResult(proc)) return proc;

  writeInput(proc, command.input);

  const [stdout, stderr, exitCode] = await Promise.all([
    readOutput(proc.stdout, command.mirrorStdout),
    readOutput(proc.stderr, command.mirrorStderr),
    proc.exited,
  ]);

  return commandResult(stdout, stderr, exitCode, command.trimOutput);
}

interface PreparedCommand {
  cwd?: string;
  env: Record<string, string>;
  input?: string;
  stdin: 'pipe' | 'ignore';
  trimOutput: boolean;
  mirrorStdout?: NodeJS.WriteStream;
  mirrorStderr?: NodeJS.WriteStream;
}

function prepareCommand(opts?: CommandOptions): PreparedCommand {
  const input = opts?.input;
  return {
    cwd: opts?.cwd,
    env: buildEnv(opts?.env),
    input,
    stdin: stdinMode(input),
    trimOutput: shouldTrimOutput(opts),
    mirrorStdout: mirrorOutput(opts?.inheritOutput, process.stdout),
    mirrorStderr: mirrorOutput(opts?.inheritOutput, process.stderr),
  };
}

function stdinMode(input?: string): 'pipe' | 'ignore' {
  return input === undefined ? 'ignore' : 'pipe';
}

function shouldTrimOutput(opts?: CommandOptions): boolean {
  return opts?.trimOutput ?? true;
}

function mirrorOutput(inheritOutput: boolean | undefined, stream: NodeJS.WriteStream): NodeJS.WriteStream | undefined {
  return inheritOutput ? stream : undefined;
}

function spawnCommand(
  cmd: string[],
  command: PreparedCommand,
): Bun.Subprocess<'pipe' | 'ignore', 'pipe', 'pipe'> | CommandResult {
  try {
    return Bun.spawn(cmd, {
      cwd: command.cwd,
      env: command.env,
      stdin: command.stdin,
      stdout: 'pipe',
      stderr: 'pipe',
    });
  } catch (e: unknown) {
    return spawnFailure(e);
  }
}

function spawnFailure(e: unknown): CommandResult {
  if (e instanceof Error && 'code' in e && e.code === 'ENOENT') return commandResult('', e.message, 127, true);
  throw e;
}

function isCommandResult(value: unknown): value is CommandResult {
  return typeof value === 'object' && value !== null && 'exitCode' in value && typeof value.exitCode === 'number';
}

function writeInput(proc: Bun.Subprocess<'pipe' | 'ignore', 'pipe', 'pipe'>, input?: string): void {
  if (input === undefined || !proc.stdin || typeof proc.stdin === 'number') {
    return;
  }

  proc.stdin.write(input);
  proc.stdin.end();
}

function commandResult(stdout: string, stderr: string, exitCode: number, trim: boolean): CommandResult {
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
