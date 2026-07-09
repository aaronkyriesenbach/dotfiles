#!/usr/bin/env bash

# Reply to a GitHub PR review thread and resolve it in one call.
#
# Usage: ./reply_and_resolve_thread.sh <thread-id> <reply-body>
#
# Posts a reply via REST API, then resolves the thread via GraphQL.

set -euo pipefail

THREAD_ID="${1:-}"
if [[ -z "${THREAD_ID}" || $# -lt 2 ]]; then
    echo "Usage: $(basename "$0") <thread-id> <reply-body>"
    exit 1
fi
REPLY_BODY="${*:2}"

command -v gh > /dev/null 2>&1 || { echo "error: gh CLI is required"; exit 1; }

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
OWNER="${REPO%/*}"
NAME="${REPO#*/}"

THREAD_CONTEXT="$(
    gh api graphql \
        -f query='
query($threadId: ID!) {
  node(id: $threadId) {
    ... on PullRequestReviewThread {
      pullRequest { number }
      comments(first: 1) {
        nodes { databaseId }
      }
    }
  }
}' \
        -f threadId="${THREAD_ID}" \
        -q '.data.node | "\(.pullRequest.number)\t\(.comments.nodes[0].databaseId)"'
)"
PR_NUMBER="${THREAD_CONTEXT%%$'\t'*}"
ROOT_COMMENT_ID="${THREAD_CONTEXT#*$'\t'}"

if [[ -z "${PR_NUMBER}" || "${PR_NUMBER}" == "null" ]]; then
    echo "error: unable to resolve PR number for thread ${THREAD_ID}"
    exit 1
fi

if [[ -z "${ROOT_COMMENT_ID}" || "${ROOT_COMMENT_ID}" == "null" ]]; then
    echo "error: unable to resolve root comment ID for thread ${THREAD_ID}"
    exit 1
fi

gh api "repos/${OWNER}/${NAME}/pulls/${PR_NUMBER}/comments/${ROOT_COMMENT_ID}/replies" \
    -X POST \
    -f body="${REPLY_BODY}" > /dev/null

gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { id isResolved }
  }
}' -f threadId="${THREAD_ID}" > /dev/null

echo "status=success"
echo "thread_id=${THREAD_ID}"
echo "pr_number=${PR_NUMBER}"
