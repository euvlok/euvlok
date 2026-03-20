import type {
  Extension,
  GithubReleaseConfig,
  BrowserType,
  GitHubRelease,
  FetchUrlResult,
} from '../types';
import { getFileExtension } from '../types';

async function token() {
  if (Bun.env.GITHUB_TOKEN) return Bun.env.GITHUB_TOKEN;

  try {
    const proc = Bun.spawn(['gh', 'auth', 'token'], { stdout: 'pipe', stderr: 'pipe' });
    await proc.exited;
    const val = (await new Response(proc.stdout).text()).trim();
    if (val.startsWith('gho_')) return val;
  } catch {
    // ignore
  }

  return null;
}

async function latest(owner: string, repo: string) {
  const headers: Record<string, string> = {
    'User-Agent': 'BrowserExtensionsUpdater',
    Accept: 'application/vnd.github.v3+json',
  };

  const auth = await token();
  if (auth) headers['Authorization'] = `token ${auth}`;

  const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/releases/latest`, {
    headers,
  });

  if (!response.ok) throw new Error(`GitHub API returned status ${response.status}`);

  const release: GitHubRelease = await response.json();
  const tag = release.tag_name ?? release.name;
  if (!tag) throw new Error('Failed to get latest release version from GitHub API');

  return tag.replace(/^v/, '');
}

export async function fetchGithubReleaseUrl(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
): Promise<FetchUrlResult> {
  const owner = ext.owner ?? config.owner;
  const repo = ext.repo ?? config.repo;
  const pattern = ext.pattern ?? config.pattern;

  if (!owner) return { error: "GitHub release source requires 'owner' field" };
  if (!repo) return { error: "GitHub release source requires 'repo' field" };

  const version = (ext.version ?? 'latest') === 'latest'
    ? await latest(owner, repo)
    : (ext.version ?? '').replace(/^v/, '');

  if (pattern) {
    const path = pattern
      .replace('{version}', version)
      .replace('{name}', ext.id)
      .replace('{id}', ext.id);
    return { url: `https://github.com/${owner}/${repo}/${path}` };
  }

  return {
    url: `https://github.com/${owner}/${repo}/releases/download/v${version}/${ext.id}.${getFileExtension(browser)}`,
  };
}
