import * as core from '@actions/core';
import type { ConsolaReporter, LogObject } from 'consola';
import { consola } from '../logger';

export const actionsLogger = consola.create({
  reporters: [
    {
      log(logObj) {
        writeAnnotation(logObj);
      },
    } satisfies ConsolaReporter,
  ],
});

export const group = core.group;

/**
 * Convert a consola log object into a GitHub Actions annotation.
 */
function writeAnnotation(logObj: LogObject): void {
  const message = formatLogObject(logObj);

  switch (logObj.type) {
    case 'error':
    case 'fatal':
      core.error(message);
      return;
    case 'warn':
      core.warning(message);
      return;
    default:
      core.notice(message);
  }
}

/**
 * Format a consola log object into a single annotation message.
 */
function formatLogObject(logObj: LogObject): string {
  const args = logObj.message ? [logObj.message, ...logObj.args] : logObj.args;
  return args.map(formatLogArg).join(' ');
}

/**
 * Format one consola argument without terminal colors.
 */
function formatLogArg(value: unknown): string {
  if (value instanceof Error) {
    return value.stack ?? value.message;
  }

  if (typeof value === 'string') {
    return value;
  }

  return Bun.inspect(value, { colors: false, depth: 5 });
}
