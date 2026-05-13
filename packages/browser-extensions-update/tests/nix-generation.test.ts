import { describe, expect, test } from 'bun:test';
import { escapeNixString, nixStringLiteral } from '@euvlok/core';
import { generateExtensionNixEntry } from '../src/nix-entry';

describe('Nix string rendering', () => {
  test('renders complete Nix string literals', () => {
    expect(nixStringLiteral('hello"$' + '{world}\n')).toBe('"hello\\"\\$' + '{world}\\n"');
  });

  test('keeps compatibility with inside-string escaping', () => {
    expect(escapeNixString('hello"$' + '{world}\n')).toBe('hello\\"\\$' + '{world}\\n');
  });

  test('uses literals when generating extension entries', () => {
    expect(
      generateExtensionNixEntry(
        {
          id: 'id"$' + '{x}',
          name: 'Test',
          source: 'url',
        },
        'https://example.test/a"$b.crx',
        'sha256-test',
        '1.0.0',
        ['tabs', 'https://example.test/*'],
        'firefox',
        'addon@example.test',
      ),
    ).toContain('pname = "id\\"\\$' + '{x}"');
  });
});
