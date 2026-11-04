import type * as Core from "@actions/core";
import type { context } from "@actions/github";
import type { GitHub as GitHubConstructor } from "@actions/github/lib/utils";
import type { RestEndpointMethodTypes } from "@octokit/plugin-rest-endpoint-methods";
import * as Predicate from "effect/Predicate";
import * as Schema from "effect/Schema";

export const BASE_BRANCH = "master";
export type GitHub = InstanceType<typeof GitHubConstructor>;
export type Repository = { owner: string; repo: string };
export type Action = {
  github: GitHub;
  context: typeof context;
  core: typeof Core;
};
export type PullRequest =
  RestEndpointMethodTypes["pulls"]["get"]["response"]["data"];
type User = { id: number; login: string; type?: string };
const isWritable = Schema.is(Schema.Literals(["write", "maintain", "admin"]));
const isDeniedStatus = Schema.is(Schema.Literals([403, 404]));

export class Refusal extends Error {}

export async function hasWriteAccess(
  github: GitHub,
  repo: Repository,
  user: User | null | undefined,
) {
  if (user?.type !== "User") return false;
  try {
    const { data } = await github.rest.repos.getCollaboratorPermissionLevel({
      ...repo,
      username: user.login,
    });
    return (
      data.user?.id === user.id &&
      data.user.type === "User" &&
      isWritable(data.permission)
    );
  } catch (error) {
    if (
      typeof error === "object" &&
      Predicate.hasProperty(error, "status") &&
      isDeniedStatus(error.status)
    )
      return false;
    throw error;
  }
}

// Report policy refusals without exposing unknown API failures
export async function runAction(
  eventName: string,
  action: Action,
  handler: (action: Action) => Promise<void>,
): Promise<void> {
  try {
    if (action.context.eventName !== eventName)
      throw new Refusal("A matching workflow event is required.");
    await handler(action);
  } catch (error) {
    action.core.setFailed(
      error instanceof Refusal
        ? error.message
        : "The command failed or its result is unconfirmed. Check the PR and Actions before running it again.",
    );
  }
}
