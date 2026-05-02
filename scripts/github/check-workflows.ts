import type { WorkflowTemplate } from '@actions/workflow-parser';
import {
  convertWorkflowTemplate,
  NoOperationTraceWriter,
  parseWorkflow,
} from '@actions/workflow-parser';
import { withTempFile } from './lib/files';
import { actionsLogger as logger } from './lib/logging';
import { restoreWorkflowCache, saveWorkflowCache, uploadWorkflowReport } from './lib/runtime';
import { listWorkflowFiles } from './lib/workflows';

await restoreWorkflowCache();
const workflowFiles = await listWorkflowFiles();
const report: WorkflowCheckReport = {
  checkedAt: new Date().toISOString(),
  workflows: [],
};
let failures = 0;

for (const workflowFile of workflowFiles) {
  const content = await Bun.file(workflowFile).text();
  const result = parseWorkflow(
    {
      name: workflowFile,
      content,
    },
    new NoOperationTraceWriter(),
  );

  const parseErrors = result.context.errors.getErrors();
  if (parseErrors.length > 0 || !result.value) {
    failures += 1;
    report.workflows.push({
      path: workflowFile,
      ok: false,
      errors: parseErrors.map((error) => error.toString()),
    });
    logger.error(`${workflowFile} failed GitHub Actions workflow parsing.`);
    for (const error of parseErrors) {
      logger.error(error.toString());
    }
    continue;
  }

  const workflow = await convertWorkflowTemplate(result.context, result.value);
  const conversionErrors = workflow.errors ?? [];
  if (conversionErrors.length > 0) {
    failures += 1;
    report.workflows.push({
      path: workflowFile,
      ok: false,
      errors: conversionErrors.map((error) => error.Message),
    });
    logger.error(`${workflowFile} failed GitHub Actions workflow conversion.`);
    for (const error of conversionErrors) {
      logger.error(error.Message);
    }
    continue;
  }

  report.workflows.push({
    path: workflowFile,
    ok: true,
    jobCount: workflow.jobs.length,
  });
  logger.info(formatWorkflowSummary(workflowFile, workflow));
}

await withTempFile(JSON.stringify(report, null, 2), 'json', uploadWorkflowReport);
await saveWorkflowCache();

if (failures > 0) {
  throw new Error(`${failures} workflow file(s) failed validation.`);
}

function formatWorkflowSummary(path: string, workflow: WorkflowTemplate): string {
  const jobCount = workflow.jobs.length;
  const jobLabel = jobCount === 1 ? 'job' : 'jobs';
  return `${path} parsed as a workflow with ${jobCount} ${jobLabel}.`;
}

interface WorkflowCheckReport {
  checkedAt: string;
  workflows: WorkflowCheckResult[];
}

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
