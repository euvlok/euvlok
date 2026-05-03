export type MaybeArray<T> = T | T[];
export type MaybePromise<T> = T | Promise<T>;

export function asArray<T>(value: MaybeArray<T>): T[] {
  return Array.isArray(value) ? value : [value];
}

export function assertNever(value: never, message = 'Unexpected value'): never {
  throw new Error(`${message}: ${String(value)}`);
}

export function nonEmptyLines(value: string, options?: { trim?: boolean }): string[] {
  const trim = options?.trim ?? true;

  return value
    .split('\n')
    .map((line) => (trim ? line.trim() : line))
    .filter((line) => line.length > 0);
}
