#!/usr/bin/env bash

# Checks the conclusion of a workflow run and reports the result.

set -euo pipefail

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

_format_msg() {
  # $1=color, $2=level, $3=message
  local color="$1"
  local level="$2"
  shift 2
  local date
  date="$(date +"%b %d %H:%M:%S")"
  printf "%s$date [%s]: %s%s\n" "$color" "$level" "$*" "$FMT_RESET" >&2
}

format_error() {
  _format_msg "${FMT_RED}${FMT_BOLD}" "ERROR" "$@"
}

format_success() {
  _format_msg "${FMT_GREEN}${FMT_BOLD}" "SUCCESS" "$@"
}

format_log() {
  _format_msg "${FMT_BOLD}" "INFO" "$@"
}

setup_colors(){
  FMT_GREEN=$(printf '\033[32m')
  FMT_RED=$(printf '\033[31m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

check_step_summary() {
  local SUMMARY_FILE="step_summary.md"
  if [ ! -f "$SUMMARY_FILE" ]; then
    format_error "$SUMMARY_FILE does not exist."
    exit 10
  fi

  if ! grep -q '| Name | Workflow | Run ID | Environment |' "$SUMMARY_FILE"; then
    format_error "Table header not found in $SUMMARY_FILE."
    exit 11
  fi

  local row_count
  row_count=$(grep -cE '^\| [^|]+ \| \[[^]]+\]\([^)]+\) \| [^|]+ \| [^|]+ \|$' "$SUMMARY_FILE")
  if [ "$row_count" -lt 1 ]; then
    format_error "No valid summary row found in $SUMMARY_FILE."
    exit 12
  fi

  format_success "$SUMMARY_FILE exists and contains the expected summary table."
}

setup() {
  touch step_summary.md
  SUMMARY_FILE=step_summary.md

  format_log "Created and using summary file: $SUMMARY_FILE"

  setup_colors

  command_exists gh || {
    format_error "gh CLI is not installed!"
    exit 1
  }

  if ! gh auth status >/dev/null 2>&1; then
    format_error "gh CLI is not authenticated. Please authenticate and try again."
    exit 1
  fi
}

main() {
  setup
  local conclusion="${GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION:-}"
  local repo_name="${GITHUB_EVENT_REPOSITORY_NAME:-}"
  local html_url="${GITHUB_EVENT_WORKFLOW_RUN_HTML_URL:-}"
  local run_number="${GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER:-}"
  local environment="${DEPLOYMENT_ENVIRONMENT:-prod}"
  local workflow_name="${WORKFLOW_NAME:-${GITHUB_EVENT_WORKFLOW_RUN_NAME:-deploy.yml}}"
  
  
  if [[ "$conclusion" == "success" ]]; then
    format_success "Workflow succeeded"
    exit 0
  else
    check_step_summary
    cat <<EOF >> "$SUMMARY_FILE"
### 🚫 Deployment Failed!

**See job:**
| Name | Workflow | Run ID | Environment |
| --- | --- | --- | --- |
| $repo_name | [$workflow_name]($html_url) | $run_number | $environment |
EOF
    format_error "Workflow failed"
    exit 1
  fi
  
}

main "$@"
