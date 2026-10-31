import * as core from "@actions/core";
import { context, getOctokit } from "@actions/github";
import type { GitHub as GitHubConstructor } from "@actions/github/lib/utils";
import type { RestEndpointMethodTypes } from "@octokit/plugin-rest-endpoint-methods";
import { Cause, Data, Effect } from "effect";

export const BASE_BRANCH = "master";
export type GitHub = InstanceType<typeof GitHubConstructor>;
export type Repository = { owner: string; repo: string };
export type PullRequest =
  RestEndpointMethodTypes["pulls"]["get"]["response"]["data"];
export type PullReview =
  RestEndpointMethodTypes["pulls"]["listReviews"]["response"]["data"][number];
type User = Pick<NonNullable<PullReview["user"]>, "id" | "login"> & {
  type?: string;
};
const WRITE_PERMISSIONS: Record<string, true> = {
  write: true,
  maintain: true,
  admin: true,
};

export class Refusal extends Data.TaggedError("Refusal")<{ message: string }> {
  constructor(message: string) {
    super({ message });
  }
}

export const hasWriteAccess = Effect.fn(function* (
  github: GitHub,
  repo: Repository,
  user: User | null | undefined,
) {
  if (user?.type !== "User") return false;
  const response = yield* Effect.tryPromise(() =>
    github.rest.repos.getCollaboratorPermissionLevel({
      ...repo,
      username: user.login,
    }),
  ).pipe(
    Effect.catchIf(
      ({ cause }) =>
        typeof cause === "object" &&
        cause !== null &&
        "status" in cause &&
        (cause.status === 403 || cause.status === 404),
      () => Effect.succeed(undefined),
    ),
  );
  return (
    response?.data.user?.id === user.id &&
    response.data.user.type === "User" &&
    Object.hasOwn(WRITE_PERMISSIONS, response.data.permission)
  );
});

// One CLI boundary reports expected refusals without exposing unknown failures
export function runAction<A, E>(
  eventName: string,
  handler: (github: GitHub) => Effect.Effect<A, E>,
): Promise<void> {
  const program = Effect.gen(function* () {
    const token = process.env.GH_TOKEN;
    if (context.eventName !== eventName || !token)
      return yield* new Refusal(
        "A matching workflow event and GitHub token are required.",
      );
    yield* handler(getOctokit(token));
  });
  return Effect.runPromise(
    program.pipe(
      Effect.catchCause((cause) =>
        Effect.sync(() => {
          const error = Cause.squash(cause);
          core.setFailed(
            error instanceof Refusal
              ? error.message
              : "The command failed or its result is unconfirmed. Check the PR and Actions before running it again.",
          );
        }),
      ),
    ),
  );
}
