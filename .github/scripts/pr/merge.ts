import type { EmitterWebhookEvent } from "@octokit/webhooks";
import {
  type Action,
  BASE_BRANCH,
  hasWriteAccess,
  Refusal,
  runAction,
} from "../github.ts";
import { requireGreenCI, requireHumanApproval } from "./checks.ts";

async function runMergeCommand({ github, context, core }: Action) {
  const { issue, comment, action } =
    context.payload as EmitterWebhookEvent<"issue_comment">["payload"];
  const repo = context.repo;
  if (
    action !== "created" ||
    !issue.pull_request ||
    comment.user?.type !== "User" ||
    comment.body.trim().toLowerCase() !== "@octocat merge"
  )
    return;
  if (!(await hasWriteAccess(github, repo, comment.user))) return;

  let body: string;
  try {
    const parameters = { ...repo, pull_number: issue.number };
    const { data: pull } = await github.rest.pulls.get(parameters);
    if (pull.state !== "open" || pull.draft || pull.base.ref !== BASE_BRANCH)
      throw new Refusal("Choose an open, non-draft PR targeting master.");
    await requireHumanApproval(
      github,
      repo,
      pull,
      Date.parse(comment.created_at),
    );
    await requireGreenCI(github, repo, pull.head.sha);
    // One immutable-head merge, no retries or bypass
    const { data: result } = await github.rest.pulls.merge({
      ...parameters,
      sha: pull.head.sha,
      merge_method: "rebase",
    });
    if (!result.merged)
      throw new Refusal(
        "GitHub did not confirm the merge. Check the PR before trying again.",
      );

    core.setOutput("merged", "true");
    body = `Merged. Master CI and configuration build dispatches: ${context.serverUrl}/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`;
  } catch (error) {
    if (!(error instanceof Refusal)) throw error;
    body = `Merge refused: ${error.message}`;
  }
  await github.rest.issues.createComment({
    ...repo,
    issue_number: issue.number,
    body,
  });
}

export default (action: Action) =>
  runAction("issue_comment", action, runMergeCommand);
