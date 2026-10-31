import * as core from "@actions/core";
import { context } from "@actions/github";
import type { EmitterWebhookEvent } from "@octokit/webhooks";
import { Effect } from "effect";
import {
  BASE_BRANCH,
  type GitHub,
  hasWriteAccess,
  Refusal,
  runAction,
} from "../github.ts";
import { requireGreenCI, requireHumanApproval } from "./checks.ts";

const MASTER_WORKFLOWS = ["ci.yml", "build-configurations.yml"] as const;

const runMergeCommand = Effect.fn(function* (github: GitHub) {
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
  if (!(yield* hasWriteAccess(github, repo, comment.user))) return;

  const body = yield* Effect.gen(function* () {
    const parameters = { ...repo, pull_number: issue.number };
    const { data: pull } = yield* Effect.tryPromise(() =>
      github.rest.pulls.get(parameters),
    );
    if (pull.state !== "open" || pull.draft || pull.base.ref !== BASE_BRANCH)
      return yield* new Refusal(
        "Choose an open, non-draft PR targeting master.",
      );
    yield* requireHumanApproval(
      github,
      repo,
      pull,
      Date.parse(comment.created_at),
    );
    yield* requireGreenCI(github, repo, pull.head.sha);
    // One immutable-head merge, no retries or bypass
    const { data: result } = yield* Effect.tryPromise(() =>
      github.rest.pulls.merge({
        ...parameters,
        sha: pull.head.sha,
        merge_method: "rebase",
      }),
    );
    if (!result.merged)
      return yield* new Refusal(
        "GitHub did not confirm the merge. Check the PR before trying again.",
      );

    // Bot merges suppress push workflows, so dispatch both master workflows
    const failed = yield* Effect.filter(MASTER_WORKFLOWS, (workflow_id) =>
      Effect.tryPromise(() =>
        github.rest.actions.createWorkflowDispatch({
          ...repo,
          workflow_id,
          ref: BASE_BRANCH,
        }),
      ).pipe(Effect.isFailure),
    );
    const message = failed.length
      ? `Merged. Master workflow dispatch unconfirmed: ${failed.join(", ")}. Check Actions before retrying.`
      : "Merged. Master CI and configuration builds dispatched.";
    if (failed.length) core.setFailed(message);
    return message;
  }).pipe(
    Effect.catchTag("Refusal", (error) =>
      Effect.succeed(`Merge refused: ${error.message}`),
    ),
  );
  yield* Effect.tryPromise(() =>
    github.rest.issues.createComment({
      ...repo,
      issue_number: issue.number,
      body,
    }),
  );
});

if (import.meta.main) await runAction("issue_comment", runMergeCommand);
