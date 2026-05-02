import { Octokit } from '@octokit/rest';
import type { BrowserType, Extension, FetchUrlResult, GithubReleaseConfig } from '../types';
import { getFileExtension } from '../types';

type GithubRelease = Awaited<ReturnType<Octokit['repos']['getLatestRelease']>>['data'];

async function getGithubToken() {
  if (Bun.env.GITHUB_TOKEN) return Bun.env.GITHUB_TOKEN;

  const gh = Bun.which('gh');
  if (!gh) return undefined;

  const proc = Bun.spawn([gh, 'auth', 'token'], { stdout: 'pipe', stderr: 'pipe' });
  if ((await proc.exited) !== 0) return undefined;

  return (await new Response(proc.stdout).text()).trim() || undefined;
}

async function githubClient(): Promise<Octokit> {
  const auth = await getGithubToken();
  return new Octokit({
    auth,
    userAgent: 'BrowserExtensionsUpdater',
  });
}

async function latest(octokit: Octokit, owner: string, repo: string): Promise<GithubRelease> {
  const release = await octokit.repos.getLatestRelease({ owner, repo });
  const tag = release.data.tag_name || release.data.name;
  if (!tag) throw new Error('Failed to get latest release version from GitHub API');

  return release.data;
}

function readReleaseConfig(ext: Extension, config: GithubReleaseConfig) {
  return {
    owner: ext.owner ?? config.owner,
    repo: ext.repo ?? config.repo,
    pattern: ext.pattern ?? config.pattern,
  };
}

function missingConfigError(owner?: string, repo?: string): FetchUrlResult | null {
  if (!owner) return { error: "GitHub release source requires 'owner' field" };
  if (!repo) return { error: "GitHub release source requires 'repo' field" };
  return null;
}

function requireReleaseTarget(owner?: string, repo?: string): { owner: string; repo: string } {
  if (!owner || !repo) throw new Error('GitHub release source missing required target');
  return { owner, repo };
}

async function releaseByVersion(
  octokit: Octokit,
  owner: string,
  repo: string,
  version: string,
): Promise<GithubRelease> {
  const normalized = version.replace(/^v/, '');
  const tags = [`v${normalized}`, normalized];

  for (const tag of tags) {
    const release = await octokit.repos.getReleaseByTag({ owner, repo, tag }).catch(() => null);
    if (release) return release.data;
  }

  throw new Error(`Failed to find GitHub release ${version}`);
}

async function resolveRelease(
  octokit: Octokit,
  ext: Extension,
  owner: string,
  repo: string,
): Promise<GithubRelease> {
  const version = ext.version ?? 'latest';
  return version === 'latest'
    ? await latest(octokit, owner, repo)
    : await releaseByVersion(octokit, owner, repo, version);
}

function releaseVersion(release: GithubRelease): string {
  const tag = release.tag_name || release.name;
  if (!tag) throw new Error('Failed to get release version from GitHub API');
  return tag.replace(/^v/, '');
}

export function interpolatePattern(pattern: string, version: string, ext: Extension): string {
  return pattern
    .replaceAll('{version}', version)
    .replaceAll('{name}', ext.id)
    .replaceAll('{id}', ext.id);
}

function releaseAssetUrl(
  ext: Extension,
  browser: BrowserType,
  release: GithubRelease,
): FetchUrlResult {
  const expectedName = `${ext.id}.${getFileExtension(browser)}`;
  const asset = release.assets.find((asset) => asset.name === expectedName);

  if (!asset) {
    return {
      error: `GitHub release ${releaseVersion(release)} does not include asset ${expectedName}`,
    };
  }

  return { url: asset.browser_download_url };
}

export async function fetchGithubReleaseUrl(
  ext: Extension,
  config: GithubReleaseConfig,
  browser: BrowserType,
): Promise<FetchUrlResult> {
  const releaseConfig = readReleaseConfig(ext, config);
  const configError = missingConfigError(releaseConfig.owner, releaseConfig.repo);
  if (configError) return configError;
  const target = requireReleaseTarget(releaseConfig.owner, releaseConfig.repo);
  const octokit = await githubClient();
  const release = await resolveRelease(octokit, ext, target.owner, target.repo);
  const version = releaseVersion(release);

  if (releaseConfig.pattern) {
    const path = interpolatePattern(releaseConfig.pattern, version, ext);
    return { url: `https://github.com/${target.owner}/${target.repo}/${path}` };
  }

  return releaseAssetUrl(ext, browser, release);
}
