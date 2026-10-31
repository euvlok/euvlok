import { Effect } from "effect";
import {
  type GitHub,
  hasWriteAccess,
  Refusal,
  type PullRequest,
  type PullReview,
  type Repository,
} from "../github.ts";

export const requireHumanApproval = Effect.fn(function* (
  github: GitHub,
  repo: Repository,
  pull: PullRequest,
  commentTime: number,
) {
  const reviews = yield* Effect.tryPromise(() =>
    github.paginate(github.rest.pulls.listReviews, {
      ...repo,
      pull_number: pull.number,
      per_page: 100,
    }),
  );
  const effective = new Map<number, PullReview>();
  reviews.sort(
    (a, b) =>
      (Date.parse(a.submitted_at ?? "") || 0) -
        (Date.parse(b.submitted_at ?? "") || 0) || a.id - b.id,
  );
  for (const review of reviews) {
    // Comments and pending reviews leave the last decisive review in effect
    if (
      review.user?.type === "User" &&
      review.submitted_at &&
      (review.state === "APPROVED" ||
        review.state === "CHANGES_REQUESTED" ||
        review.state === "DISMISSED")
    ) {
      effective.set(review.user.id, review);
    }
  }
  for (const review of effective.values()) {
    if (
      review.state === "CHANGES_REQUESTED" &&
      (yield* hasWriteAccess(github, repo, review.user))
    ) {
      return yield* new Refusal("A current collaborator requests changes.");
    }
  }
  for (const review of effective.values()) {
    if (
      review.state === "APPROVED" &&
      review.commit_id === pull.head.sha &&
      review.user?.id !== pull.user?.id &&
      Date.parse(review.submitted_at ?? "") <= commentTime &&
      (yield* hasWriteAccess(github, repo, review.user))
    ) {
      return;
    }
  }
  return yield* new Refusal(
    "The current head needs a collaborator approval before the command.",
  );
});

export const requireGreenCI = Effect.fn(function* (
  github: GitHub,
  repo: Repository,
  head: string,
) {
  const checks = yield* Effect.tryPromise(() =>
    github.paginate(github.rest.checks.listForRef, {
      ...repo,
      ref: head,
      filter: "latest",
      per_page: 100,
    }),
  );
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
    return yield* new Refusal(
      "Current-head checks need successful CI and no pending or failing results.",
    );
  }
  const { data: status } = yield* Effect.tryPromise(() =>
    github.rest.repos.getCombinedStatusForRef({ ...repo, ref: head }),
  );
  if (status.total_count > 0 && status.state !== "success") {
    return yield* new Refusal(
      "Current-head commit statuses are pending or failing.",
    );
  }
});
