import { orderBy, uniqBy } from "es-toolkit/array";
import {
  type GitHub,
  hasWriteAccess,
  Refusal,
  type PullRequest,
  type Repository,
} from "../github.ts";

const DECISIVE_STATES = ["APPROVED", "CHANGES_REQUESTED", "DISMISSED"];

type CheckRollup = {
  state: string;
  contexts: {
    nodes: ({
      conclusion?: string | null;
      checkSuite?: { app: { slug: string } | null } | null;
    } | null)[];
    pageInfo: { hasNextPage: boolean; endCursor: string | null };
  };
};

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
  let cursor: string | null = null;
  do {
    // REST's latest filter retains obsolete runs from separate check suites
    const {
      repository,
    }: {
      repository: {
        object: { statusCheckRollup: CheckRollup | null } | null;
      } | null;
    } = await github.graphql(
      `query($owner: String!, $repo: String!, $head: GitObjectID!, $cursor: String) {
        repository(owner: $owner, name: $repo) {
          object(oid: $head) {
            ... on Commit {
              statusCheckRollup {
                state
                contexts(first: 100, after: $cursor) {
                  nodes {
                    ... on CheckRun {
                      conclusion
                      checkSuite { app { slug } }
                    }
                  }
                  pageInfo { hasNextPage endCursor }
                }
              }
            }
          }
        }
      }`,
      { ...repo, head, cursor },
    );
    const rollup: CheckRollup | null | undefined =
      repository?.object?.statusCheckRollup;
    // The aggregate covers all current checks and commit statuses, on every page
    if (rollup?.state !== "SUCCESS") break;
    if (
      rollup.contexts.nodes.some(
        (check) =>
          check?.conclusion === "SUCCESS" &&
          check.checkSuite?.app?.slug === "github-actions",
      )
    )
      return;
    cursor = rollup.contexts.pageInfo.hasNextPage
      ? rollup.contexts.pageInfo.endCursor
      : null;
  } while (cursor);
  throw new Refusal(
    "Current-head checks need successful CI and no pending or failing results.",
  );
}
