import { describe, expect, test } from 'bun:test';
import { runCommandResult } from '@euvlok/core';
import { zipSync } from 'fflate';
import { join } from 'pathe';
import { extractManifestInfo } from '../src/crx-parser';
import { summarizeExtension } from '../src/extension-summary';
import { interpolatePattern } from '../src/sources/github-releases';
import { AmoAddonSchema, NixInputFileSchema } from '../src/types';

const sourceFiles = [
  'hosts/hm/ashuramaruzxc/chromium/sources.nix',
  'hosts/hm/ashuramaruzxc/firefox/sources.nix',
  'modules/hm/gui/chromium/sources.nix',
  'modules/hm/gui/firefox/sources.nix',
];

async function evaluateNixJson(path: string): Promise<unknown> {
  const result = await runCommandResult(['nix', 'eval', '--json', '--file', path]);

  if (result.exitCode !== 0) throw new Error(result.stderr);
  return JSON.parse(result.stdout);
}

describe('browser extension schemas', () => {
  test('parse all checked-in source files emitted by nix eval', async () => {
    for (const sourceFile of sourceFiles) {
      const parsed = NixInputFileSchema.parse(await evaluateNixJson(sourceFile));
      expect(parsed.browser === 'chromium' || parsed.browser === 'firefox').toBe(true);
      expect(parsed.extensions.length).toBeGreaterThan(0);
      expect(parsed.extensions.every((extension) => extension.source)).toBe(true);
    }
  });

  test('parse live AMO payload shape fields used by updater', () => {
    const addon = AmoAddonSchema.parse({
      guid: 'uBlock0@raymondhill.net',
      current_version: {
        version: '1.70.0',
        file: {
          url: 'https://addons.mozilla.org/firefox/downloads/file/4432106/clearurls-1.27.3.xpi',
          hash: 'sha256:ignored-by-updater',
          permissions: ['storage'],
        },
      },
      ignored_extra_field: true,
    });

    expect(addon.guid).toBe('uBlock0@raymondhill.net');
    expect(addon.current_version?.file?.url).toContain('addons.mozilla.org');
  });

  test('summarize nix-evaluated chromium and firefox extension entries', () => {
    const chromium = summarizeExtension(
      {
        id: 'cjpalhdlnbpafiamejdnhcphjbkeiagm',
        version: '1.70.0',
        crxPath: {
          url: 'https://clients2.googleusercontent.com/crx/blobs/sample.crx',
          hash: 'sha256-FIbmYVj8cmXce7Vq4h7d2nOjmk4RkCnABmC4y5NDyGk=',
        },
      },
      'chromium',
    );
    const firefox = summarizeExtension(
      {
        name: 'clearurls',
        version: '1.27.3',
        url: 'https://addons.mozilla.org/firefox/downloads/file/4432106/clearurls-1.27.3.xpi',
        sha256: 'sha256-VJJrbkJ01ZNaX8DapjIPHTcePS8aWHdGfKOrIqZcTyA=',
      },
      'firefox',
    );

    expect(chromium?.id).toBe('cjpalhdlnbpafiamejdnhcphjbkeiagm');
    expect(firefox?.key).toContain('clearurls|1.27.3|');
    expect(summarizeExtension({ id: 'missing-crxPath', version: '1' }, 'chromium')).toBeNull();
  });

  test('extract manifest info from real xpi-style zip manifest shape', async () => {
    const archive = zipSync({
      'manifest.json': new TextEncoder().encode(
        JSON.stringify({
          version: '1.27.3',
          permissions: ['storage', 'tabs'],
          optional_permissions: ['*://example.com/*'],
          browser_specific_settings: {
            gecko: { id: '{74145f27-f039-47ce-a470-a662b129930a}' },
          },
        }),
      ),
    });
    const path = join('/tmp', `euvlok-manifest-${crypto.randomUUID()}.xpi`);

    await Bun.write(path, archive);
    try {
      await expect(extractManifestInfo(path)).resolves.toEqual({
        version: '1.27.3',
        permissions: ['storage', 'tabs', '*://example.com/*'],
        addonId: '{74145f27-f039-47ce-a470-a662b129930a}',
      });
    } finally {
      await Bun.file(path)
        .delete()
        .catch(() => undefined);
    }
  });

  test('interpolate all github release placeholders', () => {
    expect(
      interpolatePattern('releases/download/v{version}/violentmonkey-{version}.xpi', '2.37.0', {
        id: 'violentmonkey',
        source: 'github-releases',
      }),
    ).toBe('releases/download/v2.37.0/violentmonkey-2.37.0.xpi');
  });
});
