import artifactClient from '@actions/artifact';
import * as cache from '@actions/cache';
import type { WorkflowTemplate } from '@actions/workflow-parser';
import {
  convertWorkflowTemplate,
  NoOperationTraceWriter,
  parseWorkflow,
} from '@actions/workflow-parser';
import {
  hashWorkflowFiles,
  listWorkflowFiles,
  actionsLogger as logger,
  withTempFile,
} from '@euvlok/github';

await restoreWorkflowCache();
const workflowFiles = await listWorkflowFiles();
const report: WorkflowCheckReport = {
  checkedAt: new Date().toISOString(),
  workflows: [],
};

report.workflows = await Promise.all(workflowFiles.map(checkWorkflow));

await withTempFile(JSON.stringify(report, null, 2), 'json', uploadWorkflowReport);
await saveWorkflowCache();

const failures = report.workflows.filter((workflow) => !workflow.ok);
if (failures.length > 0) {
  throw new Error(`${failures.length} workflow file(s) failed validation.`);
}

async function checkWorkflow(workflowFile: string): Promise<WorkflowCheckResult> {
  const result = parseWorkflow(
    {
      name: workflowFile,
      content: await Bun.file(workflowFile).text(),
    },
    new NoOperationTraceWriter(),
  );

  const parseErrors = result.context.errors.getErrors();
  if (parseErrors.length > 0 || !result.value) {
    logger.error(`${workflowFile} failed GitHub Actions workflow parsing.`);
    parseErrors.forEach((error) => {
      logger.error(error.toString());
    });
    return {
      path: workflowFile,
      ok: false,
      errors: parseErrors.map((error) => error.toString()),
    };
  }

  const workflow = await convertWorkflowTemplate(result.context, result.value);
  const conversionErrors = workflow.errors ?? [];
  if (conversionErrors.length > 0) {
    logger.error(`${workflowFile} failed GitHub Actions workflow conversion.`);
    conversionErrors.forEach((error) => {
      logger.error(error.Message);
    });
    return {
      path: workflowFile,
      ok: false,
      errors: conversionErrors.map((error) => error.Message),
    };
  }

  logger.info(formatWorkflowSummary(workflowFile, workflow));
  return {
    path: workflowFile,
    ok: true,
    jobCount: workflow.jobs.length,
  };
}

function formatWorkflowSummary(path: string, workflow: WorkflowTemplate): string {
  const jobCount = workflow.jobs.length;
  const jobLabel = jobCount === 1 ? 'job' : 'jobs';
  return `${path} parsed as a workflow with ${jobCount} ${jobLabel}.`;
}

function isGitHubActions(): boolean {
  return process.env.GITHUB_ACTIONS === 'true';
}

async function restoreWorkflowCache(): Promise<void> {
  if (!isGitHubActions() || !cache.isFeatureAvailable()) {
    return;
  }

  const key = await workflowCacheKey();
  const hit = await cache.restoreCache(['.github/workflows'], key, ['github-workflows-']);
  if (hit) {
    logger.info(`Restored workflow cache: ${hit}`);
  }
}

async function saveWorkflowCache(): Promise<void> {
  if (!isGitHubActions() || !cache.isFeatureAvailable()) {
    return;
  }

  const key = await workflowCacheKey();
  await cache
    .saveCache(['.github/workflows'], key)
    .then((cacheId) => logger.info(`Saved workflow cache: ${cacheId}`))
    .catch((error) => logger.warn('Workflow cache save skipped.', error));
}

async function uploadWorkflowReport(path: string): Promise<void> {
  if (!isGitHubActions()) {
    return;
  }

  const response = await artifactClient.uploadArtifact('github-workflow-check', [path], '.', {
    retentionDays: 7,
  });
  logger.info(`Uploaded workflow validation artifact ${response.id}.`);
}

async function workflowCacheKey(): Promise<string> {
  const hash = await hashWorkflowFiles();
  return `github-workflows-${hash || 'empty'}`;
}

type WorkflowCheckReport = {
  checkedAt: string;
  workflows: WorkflowCheckResult[];
};

type WorkflowCheckResult =
  | {
      path: string;
      ok: true;
      jobCount: number;
    }
  | {
      path: string;
      ok: false;
      errors: string[];
    };
