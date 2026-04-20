#!/usr/bin/env bash

# Fetch all unresolved review threads for a pull request.
#
# Usage: ./fetch_feedback.sh <pr-identifier>
#
# <pr-identifier> can be a PR number, branch name, or URL (same as gh pr view).
#
# Outputs (to stdout, key=value):
#   owner=<repo owner>
#   repo=<repo name>
#   pr_number=<PR number>
#   output_json=<path to JSON file with unresolved threads>
#   status=success

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <pr-identifier>"
    exit 1
fi

command -v gh > /dev/null 2>&1 || { echo "error: gh CLI is required"; exit 1; }
command -v jq > /dev/null 2>&1 || { echo "error: jq is required"; exit 1; }

PR_ID="${1}"

PR_JSON="$(gh pr view "${PR_ID}" --json number,headRepositoryOwner,headRepository --jq '{number, owner: .headRepositoryOwner.login, repo: .headRepository.name}')"

PR_NUMBER="$(echo "${PR_JSON}" | jq -r '.number')"
OWNER="$(echo "${PR_JSON}" | jq -r '.owner')"
REPO="$(echo "${PR_JSON}" | jq -r '.repo')"

if [[ -z "${PR_NUMBER}" || -z "${OWNER}" || -z "${REPO}" ]]; then
    echo "error: could not resolve PR identifier '${PR_ID}'"
    exit 1
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

RAW_FILE="${TEMP_DIR}/review_threads_raw.jsonl"
OUTPUT_JSON="${TEMP_DIR}/unresolved_threads.json"

QUERY="$(cat << 'EOF'
query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $endCursor) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(last: 100) {
            nodes {
              body
              createdAt
              author { login }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}
EOF
)"

gh api graphql --paginate \
    -f owner="${OWNER}" \
    -f name="${REPO}" \
    -F number="${PR_NUMBER}" \
    -f query="${QUERY}" > "${RAW_FILE}"

jq -s '
  [.[].data.repository.pullRequest.reviewThreads.nodes[]
   | select((.isResolved // false) | not)
   | {
       thread_id: .id,
       thread_status: (if .isOutdated then "outdated" else "active" end),
       path: .path,
       line: (.line // .originalLine),
       comments: [.comments.nodes[] | {
         author: .author.login,
         body: .body,
         createdAt: .createdAt
       }]
     }
  ]' "${RAW_FILE}" > "${OUTPUT_JSON}"

FINAL_OUTPUT="/tmp/pr_feedback_${OWNER}_${REPO}_${PR_NUMBER}.json"
cp "${OUTPUT_JSON}" "${FINAL_OUTPUT}"
chmod 600 "${FINAL_OUTPUT}"

echo "owner=${OWNER}"
echo "repo=${REPO}"
echo "pr_number=${PR_NUMBER}"
echo "output_json=${FINAL_OUTPUT}"
echo "status=success"
