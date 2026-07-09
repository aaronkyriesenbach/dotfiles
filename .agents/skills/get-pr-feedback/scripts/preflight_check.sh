#!/usr/bin/env bash

# Pre-flight check: verify the local checkout matches a PR's repo and branch.
#
# Usage: ./preflight_check.sh <pr-identifier>
#
# <pr-identifier> can be a PR number, branch name, or URL (same as gh pr view).
#
# Outputs (to stdout, key=value):
#   status=pass           — repo and branch both match
#   status=repo_mismatch  — current repo does not match the PR's repository
#   status=branch_mismatch — repo matches but current branch does not match
#   pr_number=<number>
#   pr_repo=<owner/repo>
#   pr_branch=<head branch>
#   current_repo=<owner/repo>
#   current_branch=<branch>
#
# Exit codes:
#   0 — check completed (read status= to determine pass/fail)
#   1 — missing arguments or tools

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <pr-identifier>"
    exit 1
fi

command -v gh > /dev/null 2>&1 || { echo "error: gh CLI is required"; exit 1; }
command -v jq > /dev/null 2>&1 || { echo "error: jq is required"; exit 1; }

PR_ID="${1}"

PR_JSON="$(gh pr view "${PR_ID}" --json number,headRefName,headRepositoryOwner,headRepository \
    --jq '{number, branch: .headRefName, owner: .headRepositoryOwner.login, repo: .headRepository.name}')"

PR_NUMBER="$(echo "${PR_JSON}" | jq -r '.number')"
PR_OWNER="$(echo "${PR_JSON}" | jq -r '.owner')"
PR_REPO="$(echo "${PR_JSON}" | jq -r '.repo')"
PR_BRANCH="$(echo "${PR_JSON}" | jq -r '.branch')"

if [[ -z "${PR_NUMBER}" || -z "${PR_OWNER}" || -z "${PR_REPO}" || -z "${PR_BRANCH}" ]]; then
    echo "error: could not resolve PR identifier '${PR_ID}'"
    exit 1
fi

CURRENT_REPO_JSON="$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')"
CURRENT_BRANCH="$(git branch --show-current)"

PR_FULL_REPO="${PR_OWNER}/${PR_REPO}"

echo "pr_number=${PR_NUMBER}"
echo "pr_repo=${PR_FULL_REPO}"
echo "pr_branch=${PR_BRANCH}"
echo "current_repo=${CURRENT_REPO_JSON}"
echo "current_branch=${CURRENT_BRANCH}"

if [[ "${CURRENT_REPO_JSON}" != "${PR_FULL_REPO}" ]]; then
    echo "status=repo_mismatch"
elif [[ "${CURRENT_BRANCH}" != "${PR_BRANCH}" ]]; then
    echo "status=branch_mismatch"
else
    echo "status=pass"
fi
