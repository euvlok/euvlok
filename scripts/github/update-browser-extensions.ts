import { basename, dirname } from 'node:path';
import { escapeNixString, exec, execSafe } from '@euvlok/shared';
import { Listr } from 'listr2';
import { simpleGit } from 'simple-git';
import { walkFiles, withTempFile } from './lib/files';
import {
  commitAndPush,
  currentRefName,
  hasGitDiff,
  listStagedFiles,
  readGitBlob,
  readGitIndex,
} from './lib/git';
import { group, actionsLogger as logger } from './lib/logging';

type BrowserType = 'chromium' | 'firefox';

type ExtensionSummary = {
  id: string;
  version: string;
  key: string;
  hash: string;
};

const browserFilter = normalizeBrowserFilter(process.env.BROWSER);
const sourceFiles = await findSourceFiles(browserFilter);

if (sourceFiles.length === 0) {
  logger.info(`No extension source files found${browserFilter ? ` for ${browserFilter}` : ''}.`);
  process.exit(0);
}

const tasks = new Listr(
  sourceFiles.map((sourceFile) => ({
    title: sourceFile,
    task: () => group(`Processing ${sourceFile}`, () => updateExtensionFile(sourceFile)),
  })),
  { concurrent: false, exitOnError: false },
);

await tasks.run();

if (!(await hasGitDiff())) {
  logger.info('No changes detected in any extension files.');
  process.exit(0);
}

logger.warn('Changes detected in one or more extension files.');
await simpleGit().add(['hosts/', 'modules/']);

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
    const result = await execSafe([
      'nix',
      'eval',
      '--json',
      '--impure',
      '--expr',
      `with import <nixpkgs> {}; import "${escapeNixString(tempFile)}" { inherit pkgs lib; config = { catppuccin.enable = false; }; }`,
    ]);

    if (result.exitCode !== 0 || !result.stdout) {
      return new Map();
    }

    const entries = JSON.parse(result.stdout) as unknown[];
    return new Map(
      entries
        .map((entry) => summarizeExtension(entry, browserType))
        .filter((entry): entry is ExtensionSummary => entry !== null)
        .map((entry) => [entry.key, entry]),
    );
  });
}

function summarizeExtension(entry: unknown, browserType: BrowserType): ExtensionSummary | null {
  const record = readRecord(entry);
  if (!record) return null;

  return browserType === 'chromium'
    ? summarizeChromiumExtension(record)
    : summarizeFirefoxExtension(record);
}

function summarizeChromiumExtension(entry: Record<string, unknown>): ExtensionSummary | null {
  const crxPath = readRecord(entry.crxPath);
  if (!crxPath) return null;

  return buildExtensionSummary({
    id: readString(entry.id),
    version: readString(entry.version),
    url: readString(crxPath.url),
    hash: readString(crxPath.hash),
  });
}

function summarizeFirefoxExtension(entry: Record<string, unknown>): ExtensionSummary | null {
  return buildExtensionSummary({
    id: readString(entry.name),
    version: readString(entry.version),
    url: readString(entry.url),
    hash: readString(entry.sha256),
  });
}

function buildExtensionSummary(input: {
  id: string;
  version: string;
  url: string;
  hash: string;
}): ExtensionSummary | null {
  if (!input.id || !input.version || !input.url) return null;

  return {
    id: input.id,
    version: input.version,
    key: `${input.id}|${input.version}|${input.url}`,
    hash: input.hash,
  };
}

function formatUpdatedExtension(
  oldEntry: ExtensionSummary | undefined,
  newEntry: ExtensionSummary,
): string[] {
  if (!oldEntry) {
    return [];
  }

  if (oldEntry.version !== newEntry.version) {
    return [`${newEntry.id}|${oldEntry.version}|${newEntry.version}`];
  }

  return oldEntry.hash !== newEntry.hash
    ? [`${newEntry.id}|${oldEntry.version}|${newEntry.version} (hash changed)`]
    : [];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function readRecord(value: unknown): Record<string, unknown> | null {
  return isRecord(value) ? value : null;
}

function readString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}
