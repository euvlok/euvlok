import * as core from '@actions/core';
import { consola } from '@euvlok/shared';
import type { ConsolaReporter, LogObject } from 'consola';

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

function formatLogObject(logObj: LogObject): string {
  const args = logObj.message ? [logObj.message, ...logObj.args] : logObj.args;
  return args.map(formatLogArg).join(' ');
}

function formatLogArg(value: unknown): string {
  if (value instanceof Error) {
    return value.stack ?? value.message;
  }

  if (typeof value === 'string') {
    return value;
  }

  return Bun.inspect(value, { colors: false, depth: 5 });
}
