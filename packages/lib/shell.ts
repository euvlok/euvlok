import type { ExecOptions as ActionsExecOptions } from '@actions/exec';
import { getExecOutput } from '@actions/exec';

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
  const [command, ...args] = cmd;
  if (!command) {
    throw new Error('Cannot execute an empty command.');
  }

  const result = await getExecOutput(command, args, buildActionsExecOptions(opts));

  const trim = opts?.trimOutput ?? true;
  return {
    stdout: trim ? result.stdout.trim() : result.stdout,
    stderr: trim ? result.stderr.trim() : result.stderr,
    exitCode: result.exitCode,
  };
}

function buildActionsExecOptions(opts?: ExecOptions): ActionsExecOptions {
  return {
    cwd: opts?.cwd,
    env: buildEnv(opts?.env),
    silent: !opts?.inheritOutput,
    ignoreReturnCode: true,
    input: inputBuffer(opts),
  };
}

function inputBuffer(opts?: ExecOptions): Buffer | undefined {
  return opts?.input === undefined ? undefined : Buffer.from(opts.input);
}

function buildEnv(overrides?: Record<string, string | undefined>): ActionsExecOptions['env'] {
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
