import { orderBy, uniqBy } from "es-toolkit/array";
import {
  type GitHub,
  hasWriteAccess,
  Refusal,
  type PullRequest,
  type Repository,
} from "../github.ts";

const DECISIVE_STATES = ["APPROVED", "CHANGES_REQUESTED", "DISMISSED"];

export async function requireHumanApproval(
  github: GitHub,
  repo: Repository,
  pull: PullRequest,
  commentTime: number,
) {
  const reviews = await github.paginate(github.rest.pulls.listReviews, {
    ...repo,
    pull_number: pull.number,
    per_page: 100,
  });
  // Keep the latest decisive review per human, including dismissals
  const effective = uniqBy(
    orderBy(
      reviews.filter(
        (review) =>
          review.user?.type === "User" &&
          review.submitted_at &&
          DECISIVE_STATES.includes(review.state),
      ),
      [(review) => Date.parse(review.submitted_at ?? "") || 0, "id"],
      ["desc", "desc"],
    ),
    (review) => review.user?.id,
  );
  for (const review of effective) {
    if (
      review.state === "CHANGES_REQUESTED" &&
      (await hasWriteAccess(github, repo, review.user))
    ) {
      throw new Refusal("A current collaborator requests changes.");
    }
  }
  for (const review of effective) {
    if (
      review.state === "APPROVED" &&
      review.commit_id === pull.head.sha &&
      review.user?.id !== pull.user?.id &&
      Date.parse(review.submitted_at ?? "") <= commentTime &&
      (await hasWriteAccess(github, repo, review.user))
    ) {
      return;
    }
  }
  throw new Refusal(
    "The current head needs a collaborator approval before the command.",
  );
}

export async function requireGreenCI(
  github: GitHub,
  repo: Repository,
  head: string,
) {
  const checks = await github.paginate(github.rest.checks.listForRef, {
    ...repo,
    ref: head,
    filter: "latest",
    per_page: 100,
  });
  if (
    !checks.some(
      (check) =>
        check.app?.slug === "github-actions" && check.conclusion === "success",
    ) ||
    checks.some(
      (check) =>
        check.status !== "completed" ||
        (check.conclusion !== "success" &&
          check.conclusion !== "neutral" &&
          check.conclusion !== "skipped"),
    )
  ) {
    throw new Refusal(
      "Current-head checks need successful CI and no pending or failing results.",
    );
  }
  const { data: status } = await github.rest.repos.getCombinedStatusForRef({
    ...repo,
    ref: head,
  });
  if (status.total_count > 0 && status.state !== "success") {
    throw new Refusal("Current-head commit statuses are pending or failing.");
  }
}
