import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { basename, dirname, join, resolve } from 'node:path';
import { buildApplication, buildCommand, run } from '@stricli/core';
import { consola } from 'consola';

type UsercssSelectOption = {
  name: string;
  default?: boolean;
};

type UsercssSelectVar = {
  value?: string;
  default?: string;
  options?: UsercssSelectOption[];
};

type UsercssMetadata = {
  name: string;
  description?: string;
  author?: string;
  url?: string;
  updateURL?: string;
  vars?: Record<string, UsercssSelectVar>;
  [key: string]: unknown;
};

type UsercssMeta = {
  parse: (sourceCode: string) => { metadata: UsercssMetadata };
  stringify: (metadata: UsercssMetadata) => string;
};

type StylusSettings = {
  settings: {
    updateInterval: number;
    updateOnlyEnabled: boolean;
    patchCsp: boolean;
    'editor.linter': string;
  };
};

type StylusUserstyle = {
  enabled: true;
  name: string;
  description?: string;
  author?: string;
  url?: string;
  updateUrl?: string;
  usercssData: UsercssMetadata;
  sourceCode: string;
  originalDigest: string;
};

type StylusImport = Array<StylusSettings | StylusUserstyle>;

const require = createRequire(import.meta.url);
const usercssMeta = require('usercss-meta') as UsercssMeta;

const SETTINGS: StylusSettings = {
  settings: {
    updateInterval: 24,
    updateOnlyEnabled: true,
    patchCsp: true,
    'editor.linter': '',
  },
};

const EXCLUDED_STYLE_IDS = ['gmail', 'shinigami-eyes'] as const;
const DEFAULT_DARK_FLAVORS = ['frappe', 'macchiato', 'mocha'];
const DEFAULT_OUTPUT_DIR = '/tmp/userstyles-output';
const USERSTYLE_HEADER_PATTERN = /\/\*\s*==UserStyle==[\s\S]*?==\/UserStyle==\s*\*\//;

type ExcludedStyleId = (typeof EXCLUDED_STYLE_IDS)[number];
type BuildFlags = {
  include: readonly ExcludedStyleId[];
};
type BuildArgs = [userstylesDir?: string, outputDir?: string];

const app = buildApplication(
  buildCommand<BuildFlags, BuildArgs>({
    docs: {
      brief: 'Build Catppuccin Stylus import variants',
      fullDescription:
        'Generates a base Stylus import and latte + dark-flavor/accent variant imports from a catppuccin/userstyles checkout.',
    },
    parameters: {
      flags: {
        include: {
          kind: 'enum',
          values: EXCLUDED_STYLE_IDS,
          variadic: ',',
          default: [],
          brief: 'Opt excluded userstyles back in',
        },
      },
      positional: {
        kind: 'tuple',
        parameters: [
          {
            parse: String,
            optional: true,
            placeholder: 'userstylesDir',
            brief: 'Path to the catppuccin/userstyles checkout',
          },
          {
            parse: String,
            optional: true,
            placeholder: 'outputDir',
            brief: 'Directory for generated Stylus import JSON files',
          },
        ],
      },
    },
    func: async ({ include }, userstylesDirArg, outputDirArg) => {
      const userstylesDir = resolve(
        userstylesDirArg ??
          process.env.USERSTYLES_DIR ??
          (await firstExistingDir(['/tmp/userstyles', '/tmp/catppuccin-userstyles'])),
      );
      const outputDir = resolve(outputDirArg ?? process.env.OUTPUT_DIR ?? DEFAULT_OUTPUT_DIR);
      const includedExcludedStyles = new Set(include);

      const allSourceFiles = await getUserstyleFiles(userstylesDir);
      const sourceFiles = allSourceFiles.filter((file) => {
        const styleId = getStyleId(file);
        return !isExcludedStyleId(styleId) || includedExcludedStyles.has(styleId);
      });
      if (sourceFiles.length === 0) {
        throw new Error(`No userstyles found under ${join(userstylesDir, 'styles')}`);
      }

      await mkdir(outputDir, { recursive: true });

      const excluded = allSourceFiles.length - sourceFiles.length;
      if (excluded > 0) {
        consola.info(
          `Excluded ${excluded} style(s): ${EXCLUDED_STYLE_IDS.filter(
            (id) => !includedExcludedStyles.has(id),
          ).join(', ')}`,
        );
      }

      const baseData = await buildStylusImport(sourceFiles);
      await writeJson(join(outputDir, 'catppuccin-import.json'), baseData);
      consola.info(`Base: ${baseData.length - 1} styles from ${userstylesDir}`);

      const firstStyle = baseData.find(isStylusUserstyle);
      if (!firstStyle) {
        throw new Error('No UserCSS styles were generated');
      }

      const accents = getSelectOptions(firstStyle.usercssData, 'accentColor').map(
        (option) => option.name,
      );

      let variants = 0;
      for (const darkFlavor of DEFAULT_DARK_FLAVORS) {
        for (const accent of accents) {
          const variant = buildVariant(baseData, {
            lightFlavor: 'latte',
            darkFlavor,
            accentColor: accent,
          });
          const name = `catppuccin-latte-${darkFlavor}-${accent}-import.json`;
          await writeJson(join(outputDir, name), variant);
          variants++;
          consola.debug(name);
        }
      }

      consola.success(`Generated ${variants} variants in ${outputDir}`);
    },
  }),
  {
    name: 'build-catppuccin-userstyles',
    versionInfo: { currentVersion: '0.0.0' },
  },
);

await run(app, Bun.argv.slice(2), { process });

async function firstExistingDir(candidates: string[]): Promise<string> {
  for (const candidate of candidates) {
    if (await Bun.file(join(candidate, 'styles')).exists()) return candidate;
  }

  return candidates[0];
}

async function getUserstyleFiles(root: string): Promise<string[]> {
  const glob = new Bun.Glob('styles/*/catppuccin.user.less');
  const files: string[] = [];

  for await (const file of glob.scan({ cwd: root, absolute: true, onlyFiles: true })) {
    files.push(file);
  }

  return files.sort((a, b) => basename(a).localeCompare(basename(b)) || a.localeCompare(b));
}

function getStyleId(file: string): string {
  return basename(dirname(file));
}

async function buildStylusImport(files: string[]): Promise<StylusImport> {
  const data: StylusImport = [SETTINGS];

  for (const file of files) {
    const sourceCode = await Bun.file(file).text();
    const { metadata } = usercssMeta.parse(sourceCode);

    data.push({
      enabled: true,
      name: metadata.name,
      description: metadata.description,
      author: metadata.author,
      url: metadata.url,
      updateUrl: metadata.updateURL,
      usercssData: metadata,
      sourceCode,
      originalDigest: calcStyleDigest(sourceCode),
    });
  }

  return data;
}

function buildVariant(
  data: StylusImport,
  defaults: Record<'lightFlavor' | 'darkFlavor' | 'accentColor', string>,
): StylusImport {
  const variant = structuredClone(data);

  for (const entry of variant) {
    if (!isStylusUserstyle(entry)) continue;

    for (const [name, value] of Object.entries(defaults)) {
      setSelectDefault(entry.usercssData, name, value);
    }

    entry.sourceCode = replaceUserstyleHeader(
      entry.sourceCode,
      usercssMeta.stringify(entry.usercssData),
    );
    entry.originalDigest = calcStyleDigest(entry.sourceCode);
  }

  return variant;
}

function setSelectDefault(metadata: UsercssMetadata, name: string, value: string): void {
  const variable = metadata.vars?.[name];
  if (!variable) return;

  const options = getSelectOptions(metadata, name);
  if (!options.some((option) => option.name === value)) {
    throw new Error(`Unknown ${name} value "${value}" for ${metadata.name}`);
  }

  variable.default = value;
  variable.value = value;
  for (const option of options) {
    option.default = option.name === value;
  }
}

function getSelectOptions(metadata: UsercssMetadata, name: string): UsercssSelectOption[] {
  const options = metadata.vars?.[name]?.options;
  if (!Array.isArray(options)) {
    throw new Error(`Missing select variable "${name}" in ${metadata.name}`);
  }

  return options;
}

function replaceUserstyleHeader(sourceCode: string, header: string): string {
  if (!USERSTYLE_HEADER_PATTERN.test(sourceCode)) {
    throw new Error('Missing UserStyle metadata header');
  }

  return sourceCode.replace(USERSTYLE_HEADER_PATTERN, header);
}

function calcStyleDigest(sourceCode: string): string {
  return new Bun.CryptoHasher('sha1').update(sourceCode).digest('hex');
}

async function writeJson(file: string, data: unknown): Promise<void> {
  await Bun.write(file, JSON.stringify(data, null, 2));
}

function isStylusUserstyle(entry: StylusSettings | StylusUserstyle): entry is StylusUserstyle {
  return 'usercssData' in entry;
}

function isExcludedStyleId(styleId: string): styleId is ExcludedStyleId {
  return EXCLUDED_STYLE_IDS.includes(styleId as ExcludedStyleId);
}
