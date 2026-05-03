import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { basename, dirname, join, resolve } from 'node:path';
import { logger } from '@euvlok/core';
import { buildApplication, buildCommand, run } from '@stricli/core';
import { z } from 'zod';

const UsercssSelectOptionSchema = z.looseObject({
  name: z.string(),
  default: z.boolean().optional(),
});

const UsercssSelectVarSchema = z.looseObject({
  value: z.string().optional(),
  default: z.string().optional(),
  options: z.array(UsercssSelectOptionSchema).optional(),
});

const UsercssMetadataSchema = z.looseObject({
  name: z.string().min(1),
  description: z.string().optional(),
  author: z.string().optional(),
  url: z.url().optional(),
  updateURL: z.url().optional(),
  vars: z.record(z.string(), UsercssSelectVarSchema).optional(),
});

const UsercssParseResultSchema = z.object({
  metadata: UsercssMetadataSchema,
});

type UsercssSelectOption = z.output<typeof UsercssSelectOptionSchema>;
type UsercssMetadata = z.output<typeof UsercssMetadataSchema>;

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

async function resolveUserstylesDir(userstylesDirArg?: string): Promise<string> {
  return resolve(
    userstylesDirArg ??
      process.env.USERSTYLES_DIR ??
      (await firstExistingDir(['/tmp/userstyles', '/tmp/catppuccin-userstyles'])),
  );
}

function resolveOutputDir(outputDirArg?: string): string {
  return resolve(outputDirArg ?? process.env.OUTPUT_DIR ?? DEFAULT_OUTPUT_DIR);
}

function filterSourceFiles(
  files: string[],
  includedExcludedStyles: Set<ExcludedStyleId>,
): string[] {
  return files.filter((file) => {
    const styleId = getStyleId(file);
    return !isExcludedStyleId(styleId) || includedExcludedStyles.has(styleId);
  });
}

function logExcludedStyles(allCount: number, sourceCount: number, included: Set<ExcludedStyleId>) {
  const excluded = allCount - sourceCount;
  if (excluded === 0) return;

  const skipped = EXCLUDED_STYLE_IDS.filter((id) => !included.has(id)).join(', ');
  logger.info(`Excluded ${excluded} style(s): ${skipped}`);
}

async function buildVariants(outputDir: string, baseData: StylusImport): Promise<string[]> {
  const firstStyle = baseData.find(isStylusUserstyle);
  if (!firstStyle) throw new Error('No UserCSS styles were generated');

  const accents = getSelectOptions(firstStyle.usercssData, 'accentColor').map(
    (option) => option.name,
  );

  return Promise.all(
    DEFAULT_DARK_FLAVORS.flatMap((darkFlavor) =>
      accents.map(async (accent) => {
        const variant = buildVariant(baseData, {
          lightFlavor: 'latte',
          darkFlavor,
          accentColor: accent,
        });
        const name = `catppuccin-latte-${darkFlavor}-${accent}-import.json`;
        await writeJson(join(outputDir, name), variant);
        logger.debug(name);
        return name;
      }),
    ),
  );
}

async function buildCatppuccinUserstyles(
  { include }: BuildFlags,
  userstylesDirArg?: string,
  outputDirArg?: string,
): Promise<void> {
  const userstylesDir = await resolveUserstylesDir(userstylesDirArg);
  const outputDir = resolveOutputDir(outputDirArg);
  const includedExcludedStyles = new Set(include);

  const allSourceFiles = await getUserstyleFiles(userstylesDir);
  const sourceFiles = filterSourceFiles(allSourceFiles, includedExcludedStyles);
  if (sourceFiles.length === 0) {
    throw new Error(`No userstyles found under ${join(userstylesDir, 'styles')}`);
  }

  await mkdir(outputDir, { recursive: true });
  logExcludedStyles(allSourceFiles.length, sourceFiles.length, includedExcludedStyles);

  const baseData = await buildStylusImport(sourceFiles);
  await writeJson(join(outputDir, 'catppuccin-import.json'), baseData);
  logger.info(`Base: ${baseData.length - 1} styles from ${userstylesDir}`);

  const variants = await buildVariants(outputDir, baseData);
  logger.success(`Generated ${variants.length} variants in ${outputDir}`);
}

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
    func: buildCatppuccinUserstyles,
  }),
  {
    name: 'build-catppuccin-userstyles',
    versionInfo: { currentVersion: '0.0.0' },
  },
);

export async function runCatppuccinUserstylesCli(args: string[]): Promise<void> {
  await run(app, args, { process });
}

async function firstExistingDir(candidates: string[]): Promise<string> {
  return (
    (
      await Promise.all(
        candidates.map(async (candidate) => ({
          candidate,
          exists: await Bun.file(join(candidate, 'styles')).exists(),
        })),
      )
    ).find((candidate) => candidate.exists)?.candidate ?? candidates[0]
  );
}

async function getUserstyleFiles(root: string): Promise<string[]> {
  return Array.fromAsync(
    new Bun.Glob('styles/*/catppuccin.user.less').scan({
      cwd: root,
      absolute: true,
      onlyFiles: true,
    }),
  ).then((files) =>
    files.sort((a, b) => basename(a).localeCompare(basename(b)) || a.localeCompare(b)),
  );
}

function getStyleId(file: string): string {
  return basename(dirname(file));
}

async function buildStylusImport(files: string[]): Promise<StylusImport> {
  return [
    SETTINGS,
    ...(await Promise.all(
      files.map(async (file) => {
        const sourceCode = await Bun.file(file).text();
        const parsed = UsercssParseResultSchema.parse(usercssMeta.parse(sourceCode));

        return {
          enabled: true as const,
          name: parsed.metadata.name,
          description: parsed.metadata.description,
          author: parsed.metadata.author,
          url: parsed.metadata.url,
          updateUrl: parsed.metadata.updateURL,
          usercssData: parsed.metadata,
          sourceCode,
          originalDigest: calcStyleDigest(sourceCode),
        };
      }),
    )),
  ];
}

function buildVariant(
  data: StylusImport,
  defaults: Record<'lightFlavor' | 'darkFlavor' | 'accentColor', string>,
): StylusImport {
  const variant = structuredClone(data);

  variant.filter(isStylusUserstyle).forEach((entry) => {
    Object.entries(defaults).forEach(([name, value]) => {
      setSelectDefault(entry.usercssData, name, value);
    });

    entry.sourceCode = replaceUserstyleHeader(
      entry.sourceCode,
      usercssMeta.stringify(entry.usercssData),
    );
    entry.originalDigest = calcStyleDigest(entry.sourceCode);
  });

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
  options.forEach((option) => {
    option.default = option.name === value;
  });
}

function getSelectOptions(metadata: UsercssMetadata, name: string): UsercssSelectOption[] {
  const options = metadata.vars?.[name]?.options;
  if (!options) {
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
