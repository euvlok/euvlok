import { formatNixFile, logger, validateNixFile } from '@euvlok/shared';
import { buildApplication, buildCommand, run } from '@stricli/core';
import { $ } from 'bun';
import figlet from 'figlet';
import { dirname, join } from 'pathe';
import { generateNixFile } from './nix-generator';
import { parseNixInput } from './nix-parser';
import { getChromiumMajorVersion, processExtensionsWithProgress } from './processor';

type BrowserExtensionsUpdateFlags = {
  output?: string;
};

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

    if (!(await Bun.file(input).exists())) {
      logger.error(`Input file not found: ${input}`);
      process.exit(1);
    }

    logger.log(figlet.textSync('Extensions', { font: 'Standard' }));
    logger.info(`Input: ${input}`);
    logger.info(`Output: ${output}`);

    const parsed = await parseNixInput(input);

    logger.info(`Browser: ${parsed.browser}`);

    if (parsed.extensions.length === 0) {
      logger.warn(`No extensions found in ${input}`);
      process.exit(0);
    }

    logger.info(`Found ${parsed.extensions.length} extension(s) to process`);

    const version = parsed.browser === 'chromium' ? await getChromiumMajorVersion() : undefined;
    if (version) logger.info(`Chromium version: ${version}`);
    if (!version) logger.info('Firefox extensions');

    const results = await processExtensionsWithProgress(
      parsed.extensions,
      parsed.config,
      parsed.browser,
      version,
    );

    const errors = results.filter((r) => r.error);
    if (errors.length > 0) {
      logger.log('');
      logger.error(`Failed to process ${errors.length} extension(s):`);
      errors.map((e) => logger.error(`  ${e.extension.name ?? e.extension.id}: ${e.error}`));
      process.exit(1);
    }

    const nix = generateNixFile(results, parsed.conditional, parsed.browser);
    await $`mkdir -p ${dirname(output)}`.quiet();
    await Bun.write(output, nix);

    await formatNixFile(output);
    await validateNixFile(output);

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
