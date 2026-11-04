import { readFile } from "node:fs/promises";
import * as Schema from "effect/Schema";
import { type Action, BASE_BRANCH, Refusal, runAction } from "../github.ts";

const isShortTitle = Schema.is(
  Schema.String.check(Schema.isMaxCodePoints(256)),
);

async function openPull({ github, context, core }: Action) {
  const { repo, sha } = context;
  const branch = context.ref.startsWith("refs/heads/")
    ? context.ref.slice("refs/heads/".length)
    : "";
  if (!branch || branch === BASE_BRANCH)
    throw new Refusal("Choose a feature branch in the Actions branch picker.");
  const title = process.env.PR_TITLE ?? "";
  if (
    !/^[a-z0-9][a-z0-9./_-]*: \S.*$/u.test(title) ||
    !isShortTitle(title) ||
    /[\r\n\u2028\u2029]/u.test(title)
  )
    throw new Refusal(
      "Use a single-line scoped title such as ci: update action pins.",
    );
  const { data: existing } = await github.rest.pulls.list({
    ...repo,
    state: "open",
    base: BASE_BRANCH,
    head: `${repo.owner}:${branch}`,
    per_page: 100,
  });
  let number = existing[0]?.number;
  if (number === undefined) {
    // Use the template from the trusted default-branch checkout
    const body = (
      await readFile(".github/PULL_REQUEST_TEMPLATE.md", "utf8")
    ).replace(/\n+$/u, "");
    const description = process.env.PR_BODY ?? "";
    const { data: created } = await github.rest.pulls.create({
      ...repo,
      base: BASE_BRANCH,
      head: branch,
      title,
      body: description ? `${description}\n\n${body}` : body,
    });
    number = created.number;
  }
  // Refresh both existing and newly created PRs before exposing the CI head
  const { data: pull } = await github.rest.pulls.get({
    ...repo,
    pull_number: number,
  });
  if (
    pull.state !== "open" ||
    pull.base.ref !== BASE_BRANCH ||
    pull.head.repo?.full_name !== `${repo.owner}/${repo.repo}` ||
    pull.head.ref !== branch
  )
    throw new Refusal(
      "PR must remain open from the selected same-repository branch to master.",
    );
  if (pull.head.sha !== sha)
    throw new Refusal(
      "The PR head changed after dispatch. Run the workflow again.",
    );
  core.setOutput("head-sha", pull.head.sha);
  await core.summary
    .addRaw(`PR: ${pull.html_url}\n\nCI head: ${pull.head.sha}\n`)
    .write();
}

export default (action: Action) =>
  runAction("workflow_dispatch", action, openPull);
