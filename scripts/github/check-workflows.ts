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
