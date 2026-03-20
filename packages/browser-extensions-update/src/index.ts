import { defineCommand, runMain } from 'citty';
import { $ } from 'bun';
import { logger, validateNixFile, formatNixFile } from '@euvlok/shared';
import { join, dirname } from 'pathe';
import figlet from 'figlet';
import { parseNixInput } from './nix-parser';
import { getChromiumMajorVersion, processExtensionsWithProgress } from './processor';
import { generateNixFile } from './nix-generator';

const main = defineCommand({
  meta: {
    name: 'browser-extensions-update',
    description: 'Generates a Nix file for browser extensions from a Nix source file',
  },
  args: {
    input: {
      type: 'string',
      alias: 'i',
      description: 'Specify the input Nix source file',
      required: true,
    },
    output: {
      type: 'string',
      alias: 'o',
      description: 'Specify the output Nix file (default: extensions.nix in the same directory)',
    },
  },
  async run({ args }) {
    const input = args.input;
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

runMain(main);
