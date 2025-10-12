#!/usr/bin/env bash

# Checks the conclusion of a workflow run and reports the result.

set -euo pipefail

main() {
  local conclusion="${GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION:-}"
  local repo_name="${GITHUB_EVENT_REPOSITORY_NAME:-}"
  local html_url="${GITHUB_EVENT_WORKFLOW_RUN_HTML_URL:-}"
  local run_number="${GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER:-}"
  local step_summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
  local environment="${DEPLOYMENT_ENVIRONMENT:-prod}"
  local workflow_name="${WORKFLOW_NAME:-${GITHUB_EVENT_WORKFLOW_RUN_NAME:-deploy.yml}}"

  if [[ "$conclusion" == "success" ]]; then
    echo "Workflow succeeded"
    exit 0
  else
    cat <<EOF >> "$step_summary"
### 🚫 Deployment Failed!

**See job:**
| Name | Workflow | Run ID | Environment |
| --- | --- | --- | --- |
| $repo_name | [$workflow_name]($html_url) | $run_number | $environment |
EOF
    echo "Workflow failed"
    exit 1
  fi
}

main "$@"
