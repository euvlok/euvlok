#! /usr/bin/env nix-shell
#! nix-shell -i bash -p git jujutsu ripgrep sd
# shellcheck shell=bash
#
# Author: FlameFlag
#
#/ Usage: SCRIPTNAME [OPTIONS]
#/
#/ Fetch the latest changes from remote and automatically rebase local changes
#/ on top of the latest remote if there are no conflicts.
#/
#/ The script will:
#/   1. Create a backup of the current state
#/   2. Fetch latest changes from remote
#/   3. Check if local changes exist (uncommitted or commits ahead of remote)
#/   4. Check if remote has new changes
#/   5. If both exist, check if rebasing would be safe (no conflicts)
#/   6. If safe, automatically rebase local changes onto latest remote
#/   7. If not safe, warn the user about potential conflicts
#/
#/ Uses Jujutsu (jj) for all operations, temporarily initializing it if needed.
#/
#/ OPTIONS
#/   -h, --help
#/                Print this help message.
#/   -b, --branch <branch-name>
#/                Specify the branch to work on (default: current branch).
#/   --dry-run
#/                Show what would be done without actually rebasing.
#/   --no-auto-rebase
#/                Only check rebase safety, don't automatically rebase.
#/   --backup-dir <directory>
#/                Directory to store backup bundle (default: /tmp).
#/
#/ EXAMPLES
#/   # Automatically rebase local changes onto latest remote if safe
#/   SCRIPTNAME
#/
#/   # Work on a specific branch
#/   SCRIPTNAME --branch feature-branch
#/
#/   # Dry run to see what would happen
#/   SCRIPTNAME --dry-run
#/
#/   # Check safety but don't auto-rebase
#/   SCRIPTNAME --no-auto-rebase

set -euo pipefail

#{{{ Constants

SCRIPT_NAME=$(basename "${0}")
readonly SCRIPT_NAME

IFS=$'\t\n'

# Repository identification
readonly EUVLOK_MARKER_FILE=".euvlok"
readonly GIT_DIR=".git"
readonly JJ_DIR=".jj"
readonly FLAKE_FILE="flake.nix"

# Git/GitHub defaults
readonly DEFAULT_REMOTE="origin"
readonly DEFAULT_BACKUP_DIR="/tmp"
readonly DETACHED_HEAD="HEAD"

# Common branch names (in order of preference)
readonly -a COMMON_BRANCH_NAMES=("master" "main" "trunk")

# State recovery
readonly STATE_MARKER=".auto-rebase-state"
readonly EUVLOK_TMP_DIR=".euvlok/tmp"

# JJ template strings
readonly JJ_TEMPLATE_COMMIT_ID='commit_id.short() + "\n"'
readonly JJ_TEMPLATE_DESCRIPTION='description.first_line() + "\n"'
readonly JJ_TEMPLATE_BOOKMARKS='{bookmarks}\n'

#}}}

#{{{ Variables

BRANCH_NAME=""
DRY_RUN=false
AUTO_REBASE=true
REPO_ROOT=""
BACKUP_DIR="${DEFAULT_BACKUP_DIR:-/tmp}"
BACKUP_FILE=""
JJ_WAS_PRESENT=false
CLEANUP_NEEDED=false
ORIGINAL_BRANCH=""
ORIGINAL_HAD_STAGED=false
ORIGINAL_STAGED_FILES=""
STAGED_DIFF_PATH=""
UNSTAGED_DIFF_PATH=""

#}}}

#{{{ Helper functions

log_error() {
	printf "\033[0;31m[error] %s\033[0m\n" "${*}" >&2
}

log_info() {
	printf "\033[0;34m[info] %s\033[0m\n" "${*}"
}

log_success() {
	printf "\033[0;32m[success] %s\033[0m\n" "${*}"
}

log_warning() {
	printf "\033[0;33m[warning] %s\033[0m\n" "${*}"
}

show_help() {
	rg '^#/' "${BASH_SOURCE[0]}" | cut -c4- | sd "SCRIPTNAME" "${SCRIPT_NAME}"
}

find_repo_root() {
	# Start from current working directory, not script directory
	local current_dir
	current_dir=$(pwd)

	while [[ "${current_dir}" != "/" ]]; do
		if [[ -f "${current_dir}/${FLAKE_FILE}" ]] || [[ -d "${current_dir}/${GIT_DIR}" ]] || [[ -d "${current_dir}/${JJ_DIR}" ]]; then
			echo "${current_dir}"
			return 0
		fi
		current_dir=$(dirname "${current_dir}")
	done

	return 1
}

check_is_git_repo() {
	local repo_root="${1}"
	[[ -d "${repo_root}/${GIT_DIR}" ]] && git -C "${repo_root}" rev-parse --git-dir &>/dev/null 2>&1
}

check_jj_present() {
	local repo_root="${1}"
	[[ -d "${repo_root}/${JJ_DIR}" ]] && command -v jj &>/dev/null && jj log -r @ --limit 1 &>/dev/null 2>&1
}

check_is_euvlok_repo() {
	local repo_root="${1}"
	[[ -f "${repo_root}/${EUVLOK_MARKER_FILE}" ]]
}

recover_from_interrupted_state() {
	local repo_root="${1}"
	local state_file="${repo_root}/${STATE_MARKER}"
	
	if [[ ! -f "${state_file}" ]]; then
		return 0  # No interrupted state
	fi
	
	log_warning "Detected interrupted auto-rebase state. Attempting recovery..."
	
	# Read state file safely (parse instead of source to avoid code injection)
	local original_branch had_staged jj_was_present timestamp staged_files staged_diff_path unstaged_diff_path
	
	# Extract variables safely using rg and sed (no code execution)
	original_branch=$(rg -N '^ORIGINAL_BRANCH=' "${state_file}" 2>/dev/null | sed 's/^ORIGINAL_BRANCH="\(.*\)"$/\1/' | head -1 || echo "")
	had_staged=$(rg -N '^ORIGINAL_HAD_STAGED=' "${state_file}" 2>/dev/null | sed 's/^ORIGINAL_HAD_STAGED="\(.*\)"$/\1/' | head -1 || echo "false")
	staged_files=$(rg -N '^ORIGINAL_STAGED_FILES=' "${state_file}" 2>/dev/null | sed 's/^ORIGINAL_STAGED_FILES="\(.*\)"$/\1/' | head -1 || echo "")
	staged_diff_path=$(rg -N '^PATH_TO_STAGED_DIFF=' "${state_file}" 2>/dev/null | sed 's/^PATH_TO_STAGED_DIFF="\(.*\)"$/\1/' | head -1 || echo "")
	unstaged_diff_path=$(rg -N '^PATH_TO_UNSTAGED_DIFF=' "${state_file}" 2>/dev/null | sed 's/^PATH_TO_UNSTAGED_DIFF="\(.*\)"$/\1/' | head -1 || echo "")
	jj_was_present=$(rg -N '^JJ_WAS_PRESENT=' "${state_file}" 2>/dev/null | sed 's/^JJ_WAS_PRESENT="\(.*\)"$/\1/' | head -1 || echo "false")
	timestamp=$(rg -N '^TIMESTAMP=' "${state_file}" 2>/dev/null | sed 's/^TIMESTAMP=\(.*\)$/\1/' | head -1 || echo "")
	
	# Validate extracted values (basic sanity checks)
	if [[ -z "${original_branch}" ]] && [[ -z "${timestamp}" ]]; then
		log_error "State file appears corrupted or empty. Manual recovery may be needed"
		log_error "State file location: ${state_file}"
		# Remove corrupted state file to prevent retry loops
		rm -f "${state_file}"
		return 1
	fi
	
	# Export jj working copy before removing .jj
	# This ensures git state is restored from jj's working copy
	if [[ -d "${repo_root}/${JJ_DIR}" ]]; then
		log_info "Found .jj directory from interrupted run"
		log_info "Exporting jj working copy to git..."
		
		# Ensure we're on the correct branch
		if [[ "${original_branch}" != "${DETACHED_HEAD}" ]]; then
			git -C "${repo_root}" checkout "${original_branch}" &>/dev/null || true
		fi
		
		# Export jj working copy to git
		jj git export || {
			log_warning "Failed to export jj working copy during recovery"
		}
		
		log_success "Exported jj working copy to git"
		
		# Restore staging state if we have it stored
		if [[ "${had_staged}" == "true" ]] && [[ -n "${staged_diff_path:-}" ]] && [[ -f "${staged_diff_path}" ]] && [[ -n "${staged_files:-}" ]]; then
			log_info "Restoring original staging state from saved state..."
			# Unstage everything first
			git -C "${repo_root}" reset &>/dev/null || true
			
			# Check if patch can be applied before attempting
			if git -C "${repo_root}" apply --check --cached "${staged_diff_path}" &>/dev/null 2>&1; then
				if git -C "${repo_root}" apply --cached "${staged_diff_path}" &>/dev/null 2>&1; then
					log_success "Restored staged changes from saved state"
				else
					log_warning "Could not apply staged patch - attempting fallback"
					# Fallback: re-add the files
					while IFS= read -r file; do
						[[ -n "${file}" ]] && git -C "${repo_root}" add "${file}" &>/dev/null || true
					done <<< "${staged_files}"
				fi
			else
				log_warning "Context changed during rebase. Your staged changes are now unstaged to prevent corruption"
				log_warning "Original staged files: ${staged_files}"
				log_info "You may need to manually re-stage files using: git add <file>"
			fi
		fi
		
		# Remove .jj if we created it (not if it was already present)
		# NOTE: Per Phase 2.1, we now keep .jj persistent, so this logic is updated
		if [[ "${jj_was_present:-false}" != "true" ]]; then
			# Keep .jj directory per Phase 2.1 - persistent ephemerality
			log_info "Keeping .jj directory for future runs (persistent ephemerality)"
		else
			log_info "Leaving .jj directory (was present before script run)"
		fi
	fi
	
	# Clean up temp files
	if [[ -n "${staged_diff_path}" ]] && [[ -f "${staged_diff_path}" ]]; then
		rm -f "${staged_diff_path}"
	fi
	if [[ -n "${unstaged_diff_path}" ]] && [[ -f "${unstaged_diff_path}" ]]; then
		rm -f "${unstaged_diff_path}"
	fi
	
	# Remove state marker
	rm -f "${state_file}"
	log_success "Recovery completed. You can now run the script again"
	return 0
}

save_state() {
	local repo_root="${1}"
	local state_file="${repo_root}/${STATE_MARKER}"
	
	# Create state file with metadata only (no content, only file paths)
	# Use printf with proper escaping to prevent injection
	printf 'ORIGINAL_BRANCH="%s"\n' "${ORIGINAL_BRANCH:-${DETACHED_HEAD}}" > "${state_file}"
	printf 'ORIGINAL_HAD_STAGED="%s"\n' "${ORIGINAL_HAD_STAGED:-false}" >> "${state_file}"
	printf 'ORIGINAL_STAGED_FILES="%s"\n' "${ORIGINAL_STAGED_FILES:-}" >> "${state_file}"
	printf 'PATH_TO_STAGED_DIFF="%s"\n' "${STAGED_DIFF_PATH:-}" >> "${state_file}"
	printf 'PATH_TO_UNSTAGED_DIFF="%s"\n' "${UNSTAGED_DIFF_PATH:-}" >> "${state_file}"
	printf 'JJ_WAS_PRESENT="%s"\n' "${JJ_WAS_PRESENT:-false}" >> "${state_file}"
	printf 'TIMESTAMP=%d\n' "$(date +%s)" >> "${state_file}"
}

create_backup() {
	local repo_root="${1}"
	local backup_dir="${2}"

	log_info "Creating backup of current repository state..."

	if [[ "${DRY_RUN}" == true ]]; then
		log_info "  [DRY RUN] Would create backup bundle"
		return 0
	fi

	# Create backup directory if it doesn't exist
	mkdir -p "${backup_dir}" || {
		log_error "Failed to create backup directory: ${backup_dir}"
		return 1
	}

	# Generate backup filename with timestamp
	local timestamp
	timestamp=$(date +%Y%m%d-%H%M%S)
	local repo_name
	repo_name=$(basename "${repo_root}")
	local backup_file
	backup_file="${backup_dir}/${repo_name}-backup-${timestamp}.gitbundle"

	# Check if repository has any commits
	if ! git -C "${repo_root}" rev-parse HEAD &>/dev/null 2>&1; then
		log_warning "Repository has no commits. Skipping backup creation"
		return 0
	fi

	# Create git bundle backup
	# This captures the entire repository state including all refs
	git -C "${repo_root}" bundle create "${backup_file}" --all || {
		log_error "Failed to create backup bundle"
		return 1
	}

	log_success "Backup created: ${backup_file}"
	log_warning "Note: This backup contains commit history only, not uncommitted working directory changes"
	log_warning "Uncommitted changes are preserved in jj's working copy during script execution"
	log_info "To restore: git clone ${backup_file} <destination>"
	echo "${backup_file}"
	return 0
}

get_original_branch() {
	local repo_root="${1}"

	# Get current branch name
	local current_branch
	current_branch=$(git -C "${repo_root}" symbolic-ref --short HEAD 2>/dev/null || echo "")
	
	if [[ -z "${current_branch}" ]]; then
		# Detached HEAD, try to get the branch from HEAD
		current_branch=$(git -C "${repo_root}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
	fi

	echo "${current_branch}"
}

setup_jj() {
	local repo_root="${1}"
	local original_branch="${2}"

	# Phase 2.1: Persistent Ephemerality - Check if .jj exists and sync instead of reinitializing
	if [[ -d "${repo_root}/${JJ_DIR}" ]]; then
		# .jj directory exists - check if it's valid
		if check_jj_present "${repo_root}"; then
			JJ_WAS_PRESENT=true
			log_info "Jujutsu repository already present"
			# Sync with Git to pick up any changes
			log_info "Syncing jj repository with Git changes..."
			jj git fetch --remote "${DEFAULT_REMOTE}" 2>/dev/null || {
				log_warning "Failed to sync jj with git remote (continuing anyway)"
			}
			# Set bookmark for current branch
			if [[ "${original_branch}" != "${DETACHED_HEAD}" ]]; then
				jj bookmark set "${original_branch}" -r @ 2>/dev/null || true
			fi
			return 0
		else
			# .jj exists but is invalid - remove it and reinitialize
			log_warning "Found invalid .jj directory, removing and reinitializing..."
			rm -rf "${repo_root}/${JJ_DIR}" || {
				log_error "Failed to remove invalid .jj directory"
				return 1
			}
		fi
	fi

	# Check if it's a git repo
	if ! check_is_git_repo "${repo_root}"; then
		log_error "Not a git repository. Cannot initialize jujutsu"
		return 1
	fi

	log_info "Initializing jujutsu for operations..."

	if [[ "${DRY_RUN}" == true ]]; then
		log_info "  [DRY RUN] Would run: jj git init --git-repo=. && jj bookmark set"
		return 0
	fi

	# Track original staging state for validation after jj git export
	# CRITICAL: Capture both staged content AND unstaged content separately
	# because jj git export may collapse them into a single state.
	# 
	# WHY THIS IS NEEDED: Jujutsu has no concept of Git's "index" (staging area).
	# Jujutsu's working copy is a single commit state with no staged/unstaged distinction.
	# When jj git export writes back to Git, it exports the working copy commit, which
	# collapses all changes into one state. We must manually restore Git's staging area
	# to preserve the user's original staging intent.
	#
	# Phase 1.1: Store diffs in temp files, not variables (prevents memory issues)
	mkdir -p "${repo_root}/${EUVLOK_TMP_DIR}"
	local timestamp
	timestamp=$(date +%s)
	
	if ! git -C "${repo_root}" diff --cached --quiet 2>/dev/null; then
		ORIGINAL_HAD_STAGED=true
		ORIGINAL_STAGED_FILES=$(git -C "${repo_root}" diff --cached --name-only 2>/dev/null || echo "")
		# Capture staged content (index state) - stream directly to temp file
		STAGED_DIFF_PATH="${repo_root}/${EUVLOK_TMP_DIR}/staged-${timestamp}.diff"
		git -C "${repo_root}" diff --cached > "${STAGED_DIFF_PATH}" 2>/dev/null || {
			log_warning "Failed to capture staged diff"
			STAGED_DIFF_PATH=""
		}
		
		# Also capture unstaged content for files that have both staged and unstaged changes
		UNSTAGED_DIFF_PATH="${repo_root}/${EUVLOK_TMP_DIR}/unstaged-${timestamp}.diff"
		git -C "${repo_root}" diff > "${UNSTAGED_DIFF_PATH}" 2>/dev/null || {
			log_warning "Failed to capture unstaged diff"
			UNSTAGED_DIFF_PATH=""
		}
	else
		ORIGINAL_HAD_STAGED=false
		ORIGINAL_STAGED_FILES=""
		STAGED_DIFF_PATH=""
		UNSTAGED_DIFF_PATH=""
	fi

	# Initialize jj - it automatically adopts uncommitted changes as the working copy (@)
	# --git-repo already implies colocation
	jj git init --git-repo="${repo_root}" || {
		log_error "Failed to initialize jujutsu"
		return 1
	}

	CLEANUP_NEEDED=true
	
	# Save state after jj init (critical recovery point)
	save_state "${repo_root}"

	# Set bookmark for the original branch
	if [[ "${original_branch}" != "${DETACHED_HEAD}" ]]; then
		jj bookmark set "${original_branch}" -r @ 2>/dev/null || {
			log_warning "Failed to set bookmark for ${original_branch}"
		}
	fi

	CLEANUP_NEEDED=true
	
	# Save state after setup is complete
	save_state "${repo_root}"
	
	log_success "Jujutsu initialized"
	return 0
}

cleanup_jj() {
	local repo_root="${1}"
	local original_branch="${2}"

	if [[ "${JJ_WAS_PRESENT}" == true ]]; then
		# jj was already there, don't remove it
		# Ensure the bookmark is set correctly to point to current working copy
		# In colocated repos, jj manages the git branch automatically via bookmarks
		# No need for git checkout - jj's bookmark system handles branch state
		if [[ "${original_branch}" != "${DETACHED_HEAD}" ]]; then
			jj bookmark set "${original_branch}" -r @ 2>/dev/null || true
		fi
		return 0
	fi

	if [[ "${CLEANUP_NEEDED}" != true ]]; then
		return 0
	fi

	log_info "Cleaning up temporary jujutsu repository..."

	if [[ "${DRY_RUN}" == true ]]; then
		log_info "  [DRY RUN] Would export jj working copy to git (but not actually exporting)"
		# Phase 3.1: In dry run, don't export to Git - just show what would happen
		return 0
	fi

	# Export jj working copy back to git before removing .jj
	log_info "Exporting jj working copy back to git..."
	
	# Ensure we're on the correct branch before export
	if [[ "${original_branch}" != "${DETACHED_HEAD}" ]]; then
		git -C "${repo_root}" checkout "${original_branch}" &>/dev/null || {
			log_warning "Failed to checkout original branch ${original_branch}"
		}
	fi
	
	# jj git export updates git's working directory and index
	# 
	# CRITICAL: Jujutsu has no staging concept (unlike Git's index).
	# Jujutsu's working copy is a single commit state - all changes are part of one commit.
	# When exporting back to Git, jj exports this single state, which collapses any
	# staged/unstaged distinction that existed in Git. We must manually restore Git's
	# staging area from the diff we captured earlier to preserve user intent.
	#
	# This is a fundamental architectural difference: Git has 3 states (HEAD, Index, Worktree),
	# while Jujutsu has 2 (Commit, Worktree). The staging area doesn't exist in jj.
	jj git export || {
		log_warning "Failed to export jj working copy to git"
		return 1
	}
	
	# Restore original staging state if we had staged changes
	# This is critical because jj git export may have collapsed staged+unstaged into one state
	# Phase 2.2: Improved partial staging reconstruction with conflict detection
	if [[ "${ORIGINAL_HAD_STAGED}" == true ]] && [[ -n "${ORIGINAL_STAGED_FILES:-}" ]]; then
		log_info "Restoring original staging state..."
		
		# First, unstage everything to get a clean state
		git -C "${repo_root}" reset &>/dev/null || true
		
		# Phase 2.2: Check if patch can be applied before attempting
		if [[ -n "${STAGED_DIFF_PATH:-}" ]] && [[ -f "${STAGED_DIFF_PATH}" ]]; then
			# Check if the exact context can be applied (prevents corruption)
			if git -C "${repo_root}" apply --check --cached "${STAGED_DIFF_PATH}" &>/dev/null 2>&1; then
				# Context matches, safe to apply
				if git -C "${repo_root}" apply --cached "${STAGED_DIFF_PATH}" &>/dev/null 2>&1; then
					log_success "Restored staged changes to index"
				else
					log_warning "Could not apply staged patch despite check passing"
					log_warning "Original staged files: ${ORIGINAL_STAGED_FILES}"
					log_info "You may need to manually re-stage files using: git add <file>"
				fi
			else
				# Context changed during rebase - abort restoration to prevent corruption
				log_warning "Context changed during rebase. Your staged changes are now unstaged to prevent corruption"
				log_warning "Original staged files: ${ORIGINAL_STAGED_FILES}"
				log_info "You may need to manually re-stage files using: git add <file>"
			fi
		else
			# Fallback: just stage the files that were originally staged
			# This won't preserve partial staging, but it's better than nothing
			log_warning "Staged diff file not found, using fallback restoration"
			while IFS= read -r file; do
				[[ -n "${file}" ]] && git -C "${repo_root}" add "${file}" &>/dev/null || true
			done <<< "${ORIGINAL_STAGED_FILES}"
			log_warning "Restored staging by re-adding files (partial staging may be lost)"
		fi
		
		# Validate staging state was restored
		local current_staged_files
		current_staged_files=$(git -C "${repo_root}" diff --cached --name-only 2>/dev/null | sort || echo "")
		local original_staged_sorted
		original_staged_sorted=$(echo "${ORIGINAL_STAGED_FILES}" | sort || echo "")
		
		if [[ "${current_staged_files}" == "${original_staged_sorted}" ]]; then
			log_success "Staging state restored correctly"
		else
			log_warning "Staging state restoration incomplete"
			log_info "Original staged: ${ORIGINAL_STAGED_FILES}"
			log_info "Current staged: ${current_staged_files:-none}"
		fi
	else
		# No files should be staged
		local current_staged_files
		current_staged_files=$(git -C "${repo_root}" diff --cached --name-only 2>/dev/null || echo "")
		if [[ -z "${current_staged_files}" ]]; then
			log_success "Staging state preserved (no files staged)"
		else
			log_warning "Unexpected staged files after export: ${current_staged_files}"
			# Unstage them to match original state
			git -C "${repo_root}" reset &>/dev/null || {
				log_warning "Failed to unstage files"
			}
		fi
	fi
	
	log_info "Restored git state from jj working copy"
	
	# Phase 2.1: Persistent Ephemerality - Keep .jj directory for future runs
	# Do NOT remove .jj directory - it makes subsequent runs near-instantaneous
	# This also implicitly onboards the user to Jujutsu
	if [[ -d "${repo_root}/${JJ_DIR}" ]]; then
		if [[ "${JJ_WAS_PRESENT}" != true ]]; then
			log_info "Keeping .jj directory for future runs (persistent ephemerality)"
		fi
	fi

	# Clean up temp diff files
	if [[ -n "${STAGED_DIFF_PATH:-}" ]] && [[ -f "${STAGED_DIFF_PATH}" ]]; then
		rm -f "${STAGED_DIFF_PATH}"
	fi
	if [[ -n "${UNSTAGED_DIFF_PATH:-}" ]] && [[ -f "${UNSTAGED_DIFF_PATH}" ]]; then
		rm -f "${UNSTAGED_DIFF_PATH}"
	fi

	log_success "Cleanup completed"
	
	# Remove state marker at the very end (after successful cleanup)
	rm -f "${repo_root}/${STATE_MARKER}"
	
	return 0
}

get_remote_bookmark() {
	local repo_root="${1}"

	# Try to find the main remote bookmark (common names: main, master, trunk)
	for bookmark in "${COMMON_BRANCH_NAMES[@]}"; do
		if jj log -r "${bookmark}@${DEFAULT_REMOTE}" --limit 1 &>/dev/null 2>&1; then
			echo "${bookmark}@${DEFAULT_REMOTE}"
			return 0
		fi
	done

	# Fallback: get any remote bookmark from origin
	local remote_bookmark
	remote_bookmark=$(jj log -r "remote_bookmarks(remote=\"${DEFAULT_REMOTE}\")" --template "${JJ_TEMPLATE_BOOKMARKS}" --no-graph --limit 1 2>/dev/null | head -1 | awk '{print $1}' || echo "")
	
	if [[ -n "${remote_bookmark}" ]]; then
		echo "${remote_bookmark}@${DEFAULT_REMOTE}"
		return 0
	fi

	# Last resort: use remote_bookmarks() which will rebase onto all remote bookmarks
	echo "remote_bookmarks()"
	return 0
}

fetch_latest() {
	local repo_root="${1}"

	log_info "Fetching latest changes from remote..."

	if [[ "${DRY_RUN}" == true ]]; then
		log_info "  [DRY RUN] Would run: git fetch ${DEFAULT_REMOTE} && jj bookmark track && jj git fetch --remote ${DEFAULT_REMOTE}"
		return 0
	fi

	# First fetch with git to ensure remote refs are up to date
	# Check if origin remote exists
	if ! git -C "${repo_root}" remote get-url "${DEFAULT_REMOTE}" &>/dev/null 2>&1; then
		log_error "No '${DEFAULT_REMOTE}' remote configured. Cannot fetch changes"
		return 1
	fi

	git -C "${repo_root}" fetch "${DEFAULT_REMOTE}" || {
		log_error "Failed to fetch from ${DEFAULT_REMOTE}"
		return 1
	}

	# Track remote bookmark so we can detect remote changes
	# Try common branch names
	for bookmark in "${COMMON_BRANCH_NAMES[@]}"; do
		if git -C "${repo_root}" show-ref --verify --quiet "refs/remotes/${DEFAULT_REMOTE}/${bookmark}" 2>/dev/null; then
			jj bookmark track "${bookmark}@${DEFAULT_REMOTE}" 2>/dev/null || true
			break
		fi
	done

	# Then fetch with jj to update jj's view of remotes
	# Use --remote to be explicit about which remote to fetch from
	# Note: --tracked can be used but requires tracked bookmarks to exist first
	jj git fetch --remote "${DEFAULT_REMOTE}" || {
		log_error "Failed to fetch from git remote"
		return 1
	}

	log_success "Fetched latest changes from git remote"
}

check_local_changes() {
	local repo_root="${1}"

	# Check for uncommitted changes
	local status
	status=$(jj status 2>/dev/null || echo "")
	
	if echo "${status}" | rg -i "modified|added|removed|renamed" &>/dev/null; then
		log_info "Found uncommitted changes in working directory"
		return 0
	fi

	# Get the specific remote branch to compare against
	local remote_target
	remote_target=$(get_remote_bookmark "${repo_root}")

	# Check if current working copy has commits not in remote
	# Use the specific remote target instead of all remote_bookmarks()
	# Use revset: remote_target..@ means "commits in @ that are not in remote_target"
	local local_commits
	local_commits=$(jj log -r "${remote_target}..@" --no-graph -T "${JJ_TEMPLATE_COMMIT_ID}" 2>/dev/null | head -1 || echo "")
	if [[ -n "${local_commits}" ]] && echo "${local_commits}" | grep -q .; then
		# Count commits using wc -l on commit_id.short() template
		# Note: commit_id.short() always produces one line per commit, so wc -l is safe
		# If template changes in future, this assumption may break
		local count
		count=$(jj log -r "${remote_target}..@" --no-graph -T "${JJ_TEMPLATE_COMMIT_ID}" 2>/dev/null | grep -v "^$" | wc -l | tr -d ' ')
		if [[ "${count}" -gt "0" ]]; then
			log_info "Found ${count} local commit(s) ahead of remote"
			return 0
		fi
	fi

	return 1
}

check_remote_changes() {
	local repo_root="${1}"

	# Get the specific remote branch to compare against
	local remote_target
	remote_target=$(get_remote_bookmark "${repo_root}")

	# Check if remote has commits ahead of local
	# Use @..remote_target to find commits in remote that are not in @
	# Use revset: @..remote_target means "commits in remote_target that are not in @"
	local remote_commits
	remote_commits=$(jj log -r "@..${remote_target}" --no-graph -T "${JJ_TEMPLATE_COMMIT_ID}" 2>/dev/null | head -1 || echo "")
	if [[ -n "${remote_commits}" ]] && echo "${remote_commits}" | grep -q .; then
		local count
		# Count commits using wc -l on commit_id.short() template
		# Note: commit_id.short() always produces one line per commit, so wc -l is safe
		# If template changes in future, this assumption may break
		count=$(jj log -r "@..${remote_target}" --no-graph -T "${JJ_TEMPLATE_COMMIT_ID}" 2>/dev/null | grep -v "^$" | wc -l | tr -d ' ')
		if [[ "${count}" != "0" ]]; then
			log_info "Found ${count} new commit(s) on remote"
			return 0
		fi
	fi

	return 1
}

check_rebase_safety() {
	local repo_root="${1}"
	# Output variable: if rebase succeeds, we can reuse it instead of redoing
	# Set to "keep" if rebase succeeded and should be kept (optimization)
	local -n rebase_op_id_ref="${2:-REBASE_OP_ID}"

	log_info "Checking if rebase would be safe..."

	# Phase 3.1: True Dry Run - actually perform JJ operations without exporting to Git
	if [[ "${DRY_RUN}" == true ]]; then
		log_info "  [DRY RUN] Performing actual rebase in jj to show result..."
		local remote_target
		remote_target=$(get_remote_bookmark "${repo_root}")
		
		# Actually perform the rebase in jj (it's virtual until exported)
		if jj rebase -d "${remote_target}" &>/dev/null; then
			log_success "  [DRY RUN] Rebase would succeed"
			log_info "  [DRY RUN] Resulting jj log:"
			jj log -r @ --limit 5 --no-graph || true
			# Undo the dry run rebase
			jj undo &>/dev/null || true
			return 0
		else
			log_warning "  [DRY RUN] Rebase would have conflicts"
			# Undo the dry run rebase
			jj undo &>/dev/null || true
			return 1
		fi
	fi

	# Get the remote bookmark to rebase onto
	local remote_target
	remote_target=$(get_remote_bookmark "${repo_root}")

	# jj rebase is generally safer and handles conflicts better
	# We can try a test rebase
	local current_rev
	current_rev=$(jj log -r @ --template '{commit_id.short()}' --no-graph 2>/dev/null || echo "")

	if [[ -z "${current_rev}" ]]; then
		log_warning "Could not determine current revision"
		return 0
	fi

	# Try rebasing the current working copy onto remote bookmarks
	# jj rebase will show conflicts if any
	# OPTIMIZATION: If this succeeds and we're going to proceed anyway, keep it
	local rebase_output
	rebase_output=$(jj rebase -d "${remote_target}" 2>&1)
	local rebase_exit_code=$?

	if [[ "${rebase_exit_code}" == 0 ]]; then
		# Rebase succeeded - we can keep this instead of redoing
		log_success "Rebase would be safe (test rebase succeeded)"
		# Mark that we should keep this rebase (caller will check and skip perform_rebase)
		rebase_op_id_ref="keep"
		return 0
	else
		# Check if there are conflicts
		local conflicts
		conflicts=$(echo "${rebase_output}" | rg -i conflict || echo "")
		# Undo the failed rebase
		jj undo &>/dev/null || true

		if [[ -n "${conflicts}" ]]; then
			log_warning "Rebase would have conflicts. Aborting safety check"
			log_info "Please resolve conflicts manually using standard Git commands:"
			log_info "  git pull"
			return 1
		else
			log_success "Rebase appears safe (no conflicts detected)"
			return 0
		fi
	fi
}

perform_rebase() {
	local repo_root="${1}"

	# Get the remote bookmark to rebase onto
	local remote_target
	remote_target=$(get_remote_bookmark "${repo_root}")

	log_info "Rebasing current working copy onto ${remote_target}..."

	if [[ "${DRY_RUN}" == true ]]; then
		log_info "  [DRY RUN] Would run: jj rebase -d ${remote_target}"
		return 0
	fi

	# Phase 3.2: Explicit conflict handoff
	local rebase_output
	rebase_output=$(jj rebase -d "${remote_target}" 2>&1)
	local rebase_exit_code=$?

	if [[ "${rebase_exit_code}" == 0 ]]; then
		log_success "Successfully rebased onto ${remote_target}"
		# With jj, @ already contains all uncommitted changes
		return 0
	else
		# Check if there are conflicts
		local conflicts
		conflicts=$(echo "${rebase_output}" | rg -i conflict || echo "")
		
		if [[ -n "${conflicts}" ]]; then
			log_error "Rebase failed due to conflicts"
			log_warning "Conflicts detected. Aborting rebase to prevent corruption"
			# Undo the rebase operation per Zero Touch directive
			log_info "Undoing rebase operation..."
			jj undo &>/dev/null || {
				log_warning "Failed to undo rebase operation automatically"
			}
			log_info ""
			log_info "The repository has been restored to its original state"
			log_info "Please resolve conflicts manually using standard Git commands:"
			log_info "  git pull"
			log_info ""
			log_info "Backup available at: ${BACKUP_FILE}"
			return 1
		else
			log_error "Rebase failed for unknown reason"
			log_info "Output: ${rebase_output}"
			log_info "Backup available at: ${BACKUP_FILE}"
			return 1
		fi
	fi
}

check_git_locks() {
	local repo_root="${1}"
	
	# Phase 1.2: Passive lock checking - wait or abort, never bust locks
	# Check for git lock files and wait passively (max 5 seconds)
	local lock_detected=false
	
	if [[ -f "${repo_root}/${GIT_DIR}/index.lock" ]] || [[ -f "${repo_root}/${GIT_DIR}/HEAD.lock" ]]; then
		lock_detected=true
		log_warning "Git lock file detected. Waiting up to 5 seconds..."
		
		local wait_count=0
		local max_wait=10  # 10 * 0.5 = 5 seconds
		while [[ "${wait_count}" -lt "${max_wait}" ]]; do
			if [[ ! -f "${repo_root}/${GIT_DIR}/index.lock" ]] && [[ ! -f "${repo_root}/${GIT_DIR}/HEAD.lock" ]]; then
				lock_detected=false
				break
			fi
			sleep 0.5
			wait_count=$((wait_count + 1))
		done
		
		# If locks still exist after waiting, abort safely
		if [[ -f "${repo_root}/${GIT_DIR}/index.lock" ]] || [[ -f "${repo_root}/${GIT_DIR}/HEAD.lock" ]]; then
			log_error "Git locks still present after waiting. Aborting to prevent data corruption"
			log_error "Please manually resolve Git locks before running this script"
			log_error "Lock files: ${repo_root}/${GIT_DIR}/index.lock ${repo_root}/${GIT_DIR}/HEAD.lock"
			return 1
		fi
	fi
	
	return 0
}

cleanup_on_error() {
	local repo_root="${1}"
	local original_branch="${2}"
	
	log_error "Script failed. Attempting cleanup..."
	
	# Clean up temp diff files
	if [[ -n "${STAGED_DIFF_PATH:-}" ]] && [[ -f "${STAGED_DIFF_PATH}" ]]; then
		rm -f "${STAGED_DIFF_PATH}"
	fi
	if [[ -n "${UNSTAGED_DIFF_PATH:-}" ]] && [[ -f "${UNSTAGED_DIFF_PATH}" ]]; then
		rm -f "${UNSTAGED_DIFF_PATH}"
	fi
	
	cleanup_jj "${repo_root}" "${original_branch}"
	log_info "Backup available at: ${BACKUP_FILE}"
	log_warning "Note: Backup contains commit history only, not uncommitted working directory changes"
	log_info "To restore: git clone ${BACKUP_FILE} <destination>"
	log_info "If cleanup failed, run the script again - it will attempt recovery automatically"
}

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "${1}" in
		-h | --help)
			show_help
			exit 0
			;;
		-b | --branch)
			if [[ -z "${2-}" ]]; then
				log_error "--branch requires a value"
				show_help
				exit 1
			fi
			BRANCH_NAME="${2}"
			shift 2
			;;
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--no-auto-rebase)
			AUTO_REBASE=false
			shift
			;;
		--backup-dir)
			if [[ -z "${2-}" ]]; then
				log_error "--backup-dir requires a value"
				show_help
				exit 1
			fi
			BACKUP_DIR="${2}"
			shift 2
			;;
		-*)
			log_error "Unknown option: ${1}"
			show_help
			exit 1
			;;
		*)
			log_error "Unexpected argument: '${1}'"
			show_help
			exit 1
			;;
		esac
	done
}

#}}}

main() {
	parse_arguments "${@}"

	# Find repository root
	REPO_ROOT=$(find_repo_root) || {
		log_error "Could not find repository root"
		exit 1
	}
	readonly REPO_ROOT

	# Check if it's a git repo
	if ! check_is_git_repo "${REPO_ROOT}"; then
		log_error "Not a git repository"
		exit 1
	fi

	log_info "Repository root: ${REPO_ROOT}"

	# Check for and recover from interrupted state FIRST (before any other checks)
	# This must happen before euvlok check because recovery might be needed even if
	# the repo is in a broken state
	recover_from_interrupted_state "${REPO_ROOT}" || {
		log_error "Recovery failed. Please manually clean up:"
		log_error "  1. Check for .jj directory and remove if you didn't create it"
		log_error "  2. Remove ${STATE_MARKER} file if it exists"
		log_error "  3. Restore from backup if needed: ${BACKUP_DIR:-/tmp}"
		exit 1
	}

	# Check if this is an euvlok repository
	if ! check_is_euvlok_repo "${REPO_ROOT}"; then
		log_error "This is not an euvlok repository (missing ${EUVLOK_MARKER_FILE} file)"
		log_info "This script is designed to work only with the euvlok repository"
		exit 1
	fi

	# Get original branch name
	ORIGINAL_BRANCH=$(get_original_branch "${REPO_ROOT}")
	readonly ORIGINAL_BRANCH
	log_info "Original branch: ${ORIGINAL_BRANCH}"

	# Phase 1.2: Check for Git locks before proceeding (passive wait/abort)
	check_git_locks "${REPO_ROOT}" || {
		log_error "Git locks detected. Aborting"
		exit 1
	}

	# Set up error handling
	trap 'cleanup_on_error "${REPO_ROOT}" "${ORIGINAL_BRANCH}"' ERR INT TERM

	# Create backup FIRST before doing anything
	BACKUP_FILE=$(create_backup "${REPO_ROOT}" "${BACKUP_DIR}") || {
		log_error "Failed to create backup. Aborting"
		exit 1
	}
	readonly BACKUP_FILE

	# Setup jj (initialize if needed)
	setup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}" || {
		log_error "Failed to setup jujutsu"
		exit 1
	}

	# Fetch latest changes
	fetch_latest "${REPO_ROOT}" || {
		cleanup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}"
		exit 1
	}

	# Check for local changes
	local has_local_changes=false
	if check_local_changes "${REPO_ROOT}"; then
		has_local_changes=true
	fi

	# Check for remote changes
	local has_remote_changes=false
	if check_remote_changes "${REPO_ROOT}"; then
		has_remote_changes=true
	fi

	# Determine what to do
	if [[ "${has_local_changes}" == false ]] && [[ "${has_remote_changes}" == false ]]; then
		log_info "No local or remote changes detected. Nothing to do"
		cleanup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}"
		return 0
	fi

	if [[ "${has_local_changes}" == false ]] && [[ "${has_remote_changes}" == true ]]; then
		log_info "Only remote changes detected. Updating to latest remote..."
		local remote_target
		remote_target=$(get_remote_bookmark "${REPO_ROOT}")
		if [[ "${DRY_RUN}" == false ]]; then
			jj rebase -d "${remote_target}" || log_warning "Rebase failed"
		else
			# Phase 3.1: True dry run - actually perform the operation
			log_info "  [DRY RUN] Performing actual rebase in jj..."
			if jj rebase -d "${remote_target}" &>/dev/null; then
				log_success "  [DRY RUN] Rebase would succeed"
				jj log -r @ --limit 5 --no-graph || true
				jj undo &>/dev/null || true
			else
				log_warning "  [DRY RUN] Rebase would fail"
				jj undo &>/dev/null || true
			fi
		fi
		cleanup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}"
		return 0
	fi

	if [[ "${has_local_changes}" == true ]] && [[ "${has_remote_changes}" == false ]]; then
		log_info "Only local changes detected. No rebase needed"
		cleanup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}"
		return 0
	fi

	# Both local and remote changes exist - check if rebase is safe
	log_info "Both local and remote changes detected. Checking rebase safety..."

	# Check if rebase would be safe
	# OPTIMIZATION: If test rebase succeeds, we keep it instead of redoing (eliminates double-rebase)
	local REBASE_OP_ID=""
	local rebase_safe=false
	if check_rebase_safety "${REPO_ROOT}" REBASE_OP_ID; then
		rebase_safe=true
	fi

	# Perform rebase if safe and auto-rebase is enabled
	if [[ "${rebase_safe}" == true ]]; then
		if [[ "${AUTO_REBASE}" == true ]]; then
			# OPTIMIZATION: If test rebase already succeeded, we kept it - no need to redo
			if [[ "${REBASE_OP_ID}" == "keep" ]]; then
				log_info "Rebase already completed during safety check (optimization)"
				log_success "Successfully rebased local changes onto latest remote!"
			else
				log_info "Rebase is safe. Automatically rebasing..."
				perform_rebase "${REPO_ROOT}" || {
					cleanup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}"
					exit 1
				}
				log_success "Successfully rebased local changes onto latest remote!"
			fi
		else
			# If we kept the test rebase but user doesn't want auto-rebase, undo it
			if [[ "${REBASE_OP_ID}" == "keep" ]]; then
				log_info "Undoing test rebase (--no-auto-rebase is set)"
				jj undo &>/dev/null || true
			fi
			log_info "Rebase would be safe, but --no-auto-rebase is set. Skipping rebase"
		fi
	else
		log_warning "Rebase may have conflicts. Not automatically rebasing"
		log_info "Please resolve conflicts manually using standard Git commands:"
		log_info "  git pull"
		log_info ""
		log_info "Backup available at: ${BACKUP_FILE}"
	fi

	# Cleanup
	cleanup_jj "${REPO_ROOT}" "${ORIGINAL_BRANCH}"

	log_success "Operation completed!"
	if [[ "${DRY_RUN}" == true ]]; then
		log_info "This was a dry run - no changes were made"
	fi
	if [[ -n "${BACKUP_FILE}" ]]; then
		log_info "Backup saved at: ${BACKUP_FILE}"
	fi
}

#}}}

main "${@}"
