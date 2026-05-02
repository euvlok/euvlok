import { exec, logger, validateNixFile } from '@euvlok/shared';
import { buildApplication, buildCommand, run } from '@stricli/core';
import figlet from 'figlet';
import { dirname, join } from 'pathe';
import { generateNixFile } from './nix-generator';
import { parseNixInput } from './nix-parser';
import { getChromiumMajorVersion, processExtensionsWithProgress } from './processor';

type BrowserExtensionsUpdateFlags = {
  output?: string;
};

async function requireInputFile(input: string): Promise<void> {
  if (await Bun.file(input).exists()) return;
  logger.error(`Input file not found: ${input}`);
  process.exit(1);
}

function logHeader(input: string, output: string): void {
  logger.log(figlet.textSync('Extensions', { font: 'Standard' }));
  logger.info(`Input: ${input}`);
  logger.info(`Output: ${output}`);
}

async function browserVersion(browser: string): Promise<string | undefined> {
  if (browser !== 'chromium') return undefined;
  const version = await getChromiumMajorVersion();
  logger.info(`Chromium version: ${version}`);
  return version;
}

function logBrowser(browser: string, version?: string): void {
  logger.info(`Browser: ${browser}`);
  if (!version) logger.info('Firefox extensions');
}

function exitOnErrors(results: Awaited<ReturnType<typeof processExtensionsWithProgress>>): void {
  const errors = results.filter((r) => r.error);
  if (errors.length === 0) return;

  logger.log('');
  logger.error(`Failed to process ${errors.length} extension(s):`);
  errors.map((e) => logger.error(`  ${e.extension.name ?? e.extension.id}: ${e.error}`));
  process.exit(1);
}

async function writeOutput(output: string, nix: string): Promise<void> {
  await exec(['mkdir', '-p', dirname(output)]);
  await Bun.write(output, nix);

  await formatNixFile(output);
  await validateNixFile(output);
}

async function formatNixFile(filePath: string): Promise<void> {
  await exec(['nix', 'run', 'nixpkgs#nixfmt', '--', filePath]);
}

const command = buildCommand<BrowserExtensionsUpdateFlags, [string]>({
  docs: {
    brief: 'Generate a browser extensions Nix file',
    fullDescription: 'Generates a Nix file for browser extensions from a Nix source file.',
  },
  parameters: {
    flags: {
      output: {
        kind: 'parsed',
        parse: String,
        brief: 'Output Nix file. Defaults to extensions.nix in the input directory.',
        optional: true,
      },
    },
    aliases: {
      o: 'output',
    },
    positional: {
      kind: 'tuple',
      parameters: [
        {
          parse: String,
          brief: 'Input Nix source file.',
          placeholder: 'input',
        },
      ],
    },
  },
  async func(args, input) {
    const output = args.output ?? join(dirname(input), 'extensions.nix');

    await requireInputFile(input);
    logHeader(input, output);

    const parsed = await parseNixInput(input);
    if (parsed.extensions.length === 0) {
      logger.warn(`No extensions found in ${input}`);
      process.exit(0);
    }

    logger.info(`Found ${parsed.extensions.length} extension(s) to process`);

    const version = await browserVersion(parsed.browser);
    logBrowser(parsed.browser, version);

    const results = await processExtensionsWithProgress(
      parsed.extensions,
      parsed.config,
      parsed.browser,
      version,
    );

    exitOnErrors(results);

    const nix = generateNixFile(results, parsed.conditional, parsed.browser);
    await writeOutput(output, nix);

    logger.log('');
    logger.success(`Generated ${output}`);
  },
});

const app = buildApplication(command, {
  name: 'browser-extensions-update',
  scanner: {
    caseStyle: 'allow-kebab-for-camel',
  },
});

await run(app, Bun.argv.slice(2), { process });
