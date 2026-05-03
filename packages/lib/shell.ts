export interface ExecResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

export interface ExecOptions {
  cwd?: string;
  env?: Record<string, string | undefined>;
  input?: string;
  inheritOutput?: boolean;
  trimOutput?: boolean;
}

/**
 * Execute a shell command and return the trimmed stdout.
 * Throws on non-zero exit code.
 */
export async function exec(cmd: string[], opts?: ExecOptions): Promise<string> {
  const result = await execSafe(cmd, opts);

  if (result.exitCode !== 0) {
    throw new Error(`Command failed (exit ${result.exitCode}): ${cmd.join(' ')}\n${result.stderr}`);
  }

  return result.stdout;
}

/**
 * Execute a shell command and return the result without throwing on failure.
 */
export async function execSafe(cmd: string[], opts?: ExecOptions): Promise<ExecResult> {
  if (cmd.length === 0) {
    throw new Error('Cannot execute an empty command.');
  }

  const proc = Bun.spawn(cmd, {
    cwd: opts?.cwd,
    env: buildEnv(opts?.env),
    stdin: opts?.input === undefined ? 'ignore' : 'pipe',
    stdout: 'pipe',
    stderr: 'pipe',
  });

  if (opts?.input !== undefined) {
    proc.stdin?.write(opts.input);
    proc.stdin?.end();
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

async function readOutput(
  stream: ReadableStream<Uint8Array>,
  mirror?: NodeJS.WriteStream,
): Promise<string> {
  const chunks: Uint8Array[] = [];

  for await (const chunk of stream) {
    chunks.push(chunk);
    mirror?.write(chunk);
  }

  return Buffer.concat(chunks).toString();
}

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
      Object.entries(process.env).filter(
        (entry): entry is [string, string] => entry[1] !== undefined,
      ),
    ),
  );
}
