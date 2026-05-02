import artifactClient from '@actions/artifact';
import * as cache from '@actions/cache';
import { hashFiles } from '@actions/glob';
import { actionsLogger as logger } from './logging';

export function isGitHubActions(): boolean {
  return process.env.GITHUB_ACTIONS === 'true';
}

export async function restoreWorkflowCache(): Promise<void> {
  if (!isGitHubActions() || !cache.isFeatureAvailable()) {
    return;
  }

  const key = await workflowCacheKey();
  const hit = await cache.restoreCache(['.github/workflows'], key, ['github-workflows-']);
  if (hit) {
    logger.info(`Restored workflow cache: ${hit}`);
  }
}

export async function saveWorkflowCache(): Promise<void> {
  if (!isGitHubActions() || !cache.isFeatureAvailable()) {
    return;
  }

  const key = await workflowCacheKey();
  try {
    const cacheId = await cache.saveCache(['.github/workflows'], key);
    logger.info(`Saved workflow cache: ${cacheId}`);
  } catch (error) {
    logger.warn('Workflow cache save skipped.', error);
  }
}

export async function uploadWorkflowReport(path: string): Promise<void> {
  if (!isGitHubActions()) {
    return;
  }

  const response = await artifactClient.uploadArtifact('github-workflow-check', [path], '.', {
    retentionDays: 7,
  });
  logger.info(`Uploaded workflow validation artifact ${response.id}.`);
}

async function workflowCacheKey(): Promise<string> {
  const hash = await hashFiles('.github/workflows/*.yml\n.github/workflows/*.yaml');
  return `github-workflows-${hash || 'empty'}`;
}
