export type MaybeArray<T> = T | T[];
export type MaybePromise<T> = T | Promise<T>;

/**
 * Normalize a single value or array into an array.
 */
export function toArray<T>(value: MaybeArray<T>): T[] {
  return Array.isArray(value) ? value : [value];
}

/**
 * Throw when supposedly unreachable code receives a value.
 */
export function assertNever(value: never, message = 'Unexpected value'): never {
  throw new Error(`${message}: ${String(value)}`);
}

/**
 * Split text into non-empty lines, trimming whitespace by default.
 */
export function splitNonEmptyLines(value: string, options?: { trim?: boolean }): string[] {
  const trim = options?.trim ?? true;

  return value
    .split('\n')
    .map((line) => (trim ? line.trim() : line))
    .filter((line) => line.length > 0);
}
