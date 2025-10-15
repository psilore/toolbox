#!/usr/bin/env bash

# Checks the conclusion of a workflow run and reports the result.

set -euo pipefail

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

print_version() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
  local VERSION_FILE="$SCRIPT_DIR/../../VERSION"
  
  if [[ -f "$VERSION_FILE" ]]; then
    cat "$VERSION_FILE"
  else
    echo "unknown"
  fi
}

usage() {
  cat <<EOF
${FMT_BOLD}Usage:${FMT_RESET} $(basename "$0") [OPTIONS]

Checks the conclusion of a workflow run and reports the result.

${FMT_BOLD}Options:${FMT_RESET}
  -f, --file           Write summary to step_summary.md file (default)
  -l, --log            Output summary to stdout instead of file
  -h, --help           Show this help message
  --version            Show script version

${FMT_BOLD}Examples:${FMT_RESET}
  $(basename "$0")                    # Write to file (default)
  $(basename "$0") --file             # Write to file (explicit)
  $(basename "$0") --stdout           # Output to stdout

EOF
  exit 0
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
  setup_colors
  
  if [[ "${OUTPUT_MODE}" == "file" ]]; then
    touch step_summary.md
    SUMMARY_FILE=step_summary.md
    format_log "Created and using summary file: $SUMMARY_FILE"
  else
    format_log "Output mode: stdout"
  fi
}

write_summary() {
  local content="$1"
  
  if [[ "${OUTPUT_MODE}" == "file" ]]; then
    echo "$content" >> "$SUMMARY_FILE"
  else
    echo "$content"
  fi
}

main() {
  setup
  # Default output mode
  OUTPUT_MODE="file"
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--file)
        OUTPUT_MODE="file"
        shift
        ;;
      -l|--log)
        OUTPUT_MODE="stdout"
        shift
        ;;
      -h|--help)
        usage
        ;;
      --version)
        print_version
        exit 0
        ;;
      *)
        setup_colors
        format_error "Unknown option: $1"
        usage
        ;;
    esac
  done
  
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
    if [[ "${OUTPUT_MODE}" == "file" ]]; then
      check_step_summary
    fi
    
    local summary_content
    summary_content=$(cat <<EOF
### 🚫 Deployment Failed!

**See job:**
| Name | Workflow | Run ID | Environment |
| --- | --- | --- | --- |
| $repo_name | [$workflow_name]($html_url) | $run_number | $environment |
EOF
)
    
    write_summary "$summary_content"
    format_error "Workflow failed"
    exit 1
  fi
}

main "$@"