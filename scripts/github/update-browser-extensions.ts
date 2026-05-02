import { basename, dirname } from 'node:path';
import {
  commitAndPush,
  currentRefName,
  hasGitDiff,
  actionsLogger as logger,
  runSequentialTasks,
  walkFiles,
  withTempFile,
} from '@euvlok/github';
import {
  addGitPaths,
  escapeNixString,
  exec,
  listStagedFiles,
  nixEvalJson,
  readGitBlob,
  readGitIndex,
} from '@euvlok/shared';
import { z } from 'zod';
import {
  type ExtensionSummary,
  formatUpdatedExtension,
  summarizeExtension,
} from '../../packages/browser-extensions-update/src/extension-summary';
import type { BrowserType } from '../../packages/browser-extensions-update/src/types';

const browserFilter = normalizeBrowserFilter(process.env.BROWSER);
const sourceFiles = await findSourceFiles(browserFilter);

if (sourceFiles.length === 0) {
  logger.info(`No extension source files found${browserFilter ? ` for ${browserFilter}` : ''}.`);
  process.exit(0);
}

await runSequentialTasks(sourceFiles, String, updateExtensionFile);

if (!(await hasGitDiff())) {
  logger.info('No changes detected in any extension files.');
  process.exit(0);
}

logger.warn('Changes detected in one or more extension files.');
await addGitPaths(['hosts/', 'modules/']);

const changedExtensionFiles = (await listStagedFiles())
  .filter((file) => file.endsWith('extensions.nix'))
  .sort((a, b) => a.localeCompare(b));

const changes = (
  await Promise.all(changedExtensionFiles.map((file) => analyzeFileChanges(file)))
).filter(Boolean);

const commitTitle = browserFilter
  ? `chore(${browserFilter}): update extensions`
  : 'chore(browsers): update extensions';

await commitAndPush({
  title: commitTitle,
  body: changes.length > 0 ? `\n${changes.join('\n')}` : '\nUpdated extension definitions.',
  add: ['hosts/', 'modules/'],
  refName: currentRefName(),
});

function normalizeBrowserFilter(input: string | undefined): BrowserType | null {
  if (!input || input === 'all') {
    return null;
  }
  if (input === 'chromium' || input === 'firefox') {
    return input;
  }

  throw new Error(`Unsupported browser filter: ${input}`);
}

async function updateExtensionFile(sourceFile: string): Promise<void> {
  await exec(['bun', 'run', 'browser-extension-update', '--', '-i', sourceFile], {
    inheritOutput: true,
  });
}

async function findSourceFiles(filter: BrowserType | null): Promise<string[]> {
  const roots = ['modules', 'hosts'];
  const files = (
    await Promise.all(
      roots.map((root) => walkFiles(root, (path) => basename(path) === 'sources.nix')),
    )
  ).flat();

  return files.filter((file) => !filter || basename(dirname(file)) === filter);
}

async function analyzeFileChanges(nixFile: string): Promise<string> {
  const browserType: BrowserType = nixFile.includes('firefox') ? 'firefox' : 'chromium';
  const [headContent, stagedContent] = await Promise.all([
    readGitBlob('HEAD', nixFile),
    readGitIndex(nixFile),
  ]);

  const [oldEntries, newEntries] = await Promise.all([
    parseExtensions(headContent, browserType),
    parseExtensions(stagedContent, browserType),
  ]);

  const added = [...newEntries].flatMap(([key, newEntry]) =>
    oldEntries.has(key) ? [] : [newEntry.id],
  );
  const removed = [...oldEntries].flatMap(([key, oldEntry]) =>
    newEntries.has(key) ? [] : [oldEntry.id],
  );
  const updated = [...newEntries].flatMap(([key, newEntry]) =>
    formatUpdatedExtension(oldEntries.get(key), newEntry),
  );

  if (added.length === 0 && removed.length === 0 && updated.length === 0) {
    return '';
  }

  const lines = [`${basename(dirname(nixFile))} (${browserType}):`];
  lines.push(...added.map((id) => `  + ${id}`));
  lines.push(...removed.map((id) => `  - ${id}`));
  lines.push(
    ...updated.map((item) => {
      const [id, oldVersion, newVersion] = item.split('|');
      return `  ~ ${id}: ${oldVersion} -> ${newVersion}`;
    }),
  );
  lines.push('');
  return lines.join('\n');
}

async function parseExtensions(
  nixContent: string,
  browserType: BrowserType,
): Promise<Map<string, ExtensionSummary>> {
  if (!nixContent.trim()) {
    return new Map();
  }

  return withTempFile(nixContent, 'nix', async (tempFile) => {
    const json = await nixEvalJson(
      `with import <nixpkgs> {}; import "${escapeNixString(tempFile)}" { inherit pkgs lib; config = { catppuccin.enable = false; }; }`,
    );

    if (json === null) {
      return new Map();
    }

    const entries = z.array(z.unknown()).parse(json);
    return new Map(
      entries
        .map((entry) => summarizeExtension(entry, browserType))
        .filter((entry): entry is ExtensionSummary => entry !== null)
        .map((entry) => [entry.key, entry]),
    );
  });
}
