import type { EmitterWebhookEvent } from "@octokit/webhooks";
import {
  type Action,
  BASE_BRANCH,
  hasWriteAccess,
  Refusal,
  runAction,
} from "../github.ts";

type MergeCandidate = {
  number: number;
  state: string;
  draft?: boolean;
  base: { ref: string; repo: { node_id: string } };
  head: { sha: string };
};

const REBASE_REQUIRED =
  "Rebase onto current master without merge commits and sign the rewritten commits before trying again.";

async function requireLinearHistory(
  { github, context }: Action,
  base: string,
  head: string,
) {
  if (base === head)
    throw new Refusal("Master already points to this PR head.");
  let previous = base;
  const per_page = 100;
  for (let page = 1; ; page++) {
    const { data } = await github.rest.repos.compareCommitsWithBasehead({
      ...context.repo,
      basehead: `${base}...${head}`,
      per_page,
      page,
    });
    if (data.status !== "ahead" || data.merge_base_commit.sha !== base)
      throw new Refusal(REBASE_REQUIRED);
    for (const commit of data.commits) {
      if (commit.parents.length !== 1 || commit.parents[0]?.sha !== previous)
        throw new Refusal(REBASE_REQUIRED);
      previous = commit.sha;
    }
    if (previous === head) return;
    if (data.commits.length < per_page) throw new Refusal(REBASE_REQUIRED);
  }
}

function requireMergeCandidate(pull: MergeCandidate) {
  if (pull.state !== "open" || pull.draft || pull.base.ref !== BASE_BRANCH)
    throw new Refusal("Choose an open, non-draft PR targeting master.");
}

async function fastForward(action: Action, pull: MergeCandidate) {
  const { github, context } = action;
  const head = pull.head.sha;
  const { data: ref } = await github.rest.git.getRef({
    ...context.repo,
    ref: `heads/${BASE_BRANCH}`,
  });
  const base = ref.object.sha;
  await requireLinearHistory(action, base, head);

  const { data: current } = await github.rest.pulls.get({
    ...context.repo,
    pull_number: pull.number,
  });
  requireMergeCandidate(current);
  if (current.head.sha !== head)
    throw new Refusal("The PR head changed. Try again with its current head.");

  // Check master and move it in one non-forced update, without creating commits
  const { updateRefs } = await github.graphql<{
    updateRefs: { __typename: "UpdateRefsPayload" } | null;
  }>(
    `mutation FastForward($input: UpdateRefsInput!) {
      updateRefs(input: $input) { __typename }
    }`,
    {
      input: {
        repositoryId: pull.base.repo.node_id,
        refUpdates: [
          {
            name: `refs/heads/${BASE_BRANCH}`,
            beforeOid: base,
            afterOid: head,
            force: false,
          },
        ],
      },
    },
  );
  if (!updateRefs) throw new Error("GitHub did not confirm the ref update.");
}

async function runMergeCommand(input: Action) {
  const { github, context, core } = input;
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
    requireMergeCandidate(pull);
    await fastForward(input, pull);

    core.setOutput("merged", "true");
    body = `Fast-forwarded master to \`${pull.head.sha}\`. Master CI dispatch: ${context.serverUrl}/${repo.owner}/${repo.repo}/actions/runs/${context.runId}`;
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
