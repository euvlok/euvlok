import * as core from "@actions/core";
import { context } from "@actions/github";
import { Effect, Schema } from "effect";
import { BASE_BRANCH, Refusal, runAction, type GitHub } from "../github.ts";

const TITLE_REFUSAL =
  "Use a single-line scoped title such as ci: update action pins.";
const BRANCH_REFUSAL = "Choose a feature branch in the Actions branch picker.";
const Title = Schema.String.check(
  Schema.isPattern(/^[a-z0-9][a-z0-9./_-]*: \S.*$/u),
  Schema.makeFilter((title) => !/[\r\n\u2028\u2029]/u.test(title)),
  Schema.isMaxCodePoints(256),
);

const openPull = Effect.fn(function* (github: GitHub) {
  const { repo, sha } = context;
  const branch = context.ref.startsWith("refs/heads/")
    ? context.ref.slice("refs/heads/".length)
    : "";
  if (!branch || branch === BASE_BRANCH) {
    return yield* new Refusal(BRANCH_REFUSAL);
  }
  const title = yield* Schema.decodeUnknownEffect(Title)(
    process.env.PR_TITLE ?? "",
  ).pipe(Effect.mapError(() => new Refusal(TITLE_REFUSAL)));
  const { data: existing } = yield* Effect.tryPromise(() =>
    github.rest.pulls.list({
      ...repo,
      state: "open",
      base: BASE_BRANCH,
      head: `${repo.owner}:${branch}`,
      per_page: 100,
    }),
  );
  let number = existing[0]?.number;
  if (number === undefined) {
    const template = yield* Effect.tryPromise(() =>
      Bun.file(".github/PULL_REQUEST_TEMPLATE.md").text(),
    );
    // Use the template from the trusted default-branch checkout
    const body = template.replace(/\n+$/u, "");
    const description = process.env.PR_BODY ?? "";
    const { data: created } = yield* Effect.tryPromise(() =>
      github.rest.pulls.create({
        ...repo,
        base: BASE_BRANCH,
        head: branch,
        title,
        body: description ? `${description}\n\n${body}` : body,
      }),
    );
    number = created.number;
  }
  // Refresh both existing and newly created PRs before exposing the CI head
  const { data: pull } = yield* Effect.tryPromise(() =>
    github.rest.pulls.get({ ...repo, pull_number: number }),
  );
  if (
    pull.state !== "open" ||
    pull.base.ref !== BASE_BRANCH ||
    pull.head.repo?.full_name !== `${repo.owner}/${repo.repo}` ||
    pull.head.ref !== branch
  ) {
    return yield* new Refusal(
      "PR must remain open from the selected same-repository branch to master.",
    );
  }
  if (pull.head.sha !== sha) {
    return yield* new Refusal(
      "The PR head changed after dispatch. Run the workflow again.",
    );
  }
  core.setOutput("head-sha", pull.head.sha);
  yield* Effect.tryPromise(() =>
    core.summary
      .addRaw(`PR: ${pull.html_url}\n\nCI head: ${pull.head.sha}\n`)
      .write(),
  );
});

if (import.meta.main) await runAction("workflow_dispatch", openPull);
