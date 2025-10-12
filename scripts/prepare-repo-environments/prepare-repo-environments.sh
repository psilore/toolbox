#!/usr/bin/env bash

# Script to create GitHub Environments in a repository using the gh CLI.
#
# Usage:
#+ ./prepare-repo-environments.sh [--remove] <environment-name>... [--repo <owner/repo>]
#
# Requirements:
#   - GitHub CLI (gh) must be installed and authenticated.
#
# Example:
#   ./prepare-repo-environments.sh staging production --repo psilore/toolbox
#   ./prepare-repo-environments.sh --remove staging --repo psilore/toolbox

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

#######################################
# Print usage information.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes usage to STDOUT
#######################################
usage() {
  cat >&2 <<EOF

Usage: $0 [--list] [--remove] [--version] <environment-name>... [--repo <owner/repo>]

Create or remove GitHub Environments in a repository using the gh CLI.

Options:
  --list               List existing environments in the repository.
  --remove             Remove the specified environments instead of creating them.
  --version            Show script version
  <environment-name>   One or more environment names to create or remove.
  --repo <owner/repo>  Target repository in owner/repo format (optional, defaults to current repo).

Examples:
  $0 --list --repo <owner/repo>
    # Lists all environments in <owner/repo>

  $0 dev prod staging --repo <owner/repo>
    # Creates 'dev', 'prod', and 'staging' environments in <owner/repo>

  $0 --remove dev --repo <owner/repo>
    # Removes the 'dev' environment from <owner/repo>

  $0 test
    # Creates 'test' environment in the current repository
  $0 --version
    # Show script version
EOF
  exit 1
}

print_version() {
  echo "$SCRIPT_VERSION"
}

# List environments in a repository
list_environments() {
  local repo_path env_name
  repo_path="$1"
  format_log "Listing environments for repository: $repo_path"
  if ! gh api "repos/${repo_path}/environments" | jq -r '.environments[]?.name' | while IFS= read -r env_name; do
    if [[ -n "$env_name" ]]; then
      format_success "$env_name"
    fi
  done; then
    format_error "Failed to list environments for repository: $repo_path"
    return 1
  fi
  # Check if any environments were found
  if [[ $(gh api "repos/${repo_path}/environments" | jq -r '.environments[]?.name' | wc -l) -eq 0 ]]; then
    format_log "no environments found"
  fi
}

#######################################
# Create a GitHub environment using gh CLI.
# Globals:
#   None
# Arguments:
#   --remove: Remove environments instead of creating them
#   Environment name
#   --repo <owner/repo> (optional, defaults to current repo)
# Outputs:
#   Writes status to STDOUT/STDERR
# Returns:
#   0 on success, non-zero on error
#######################################
create_environment() {
  local env_name repo_path
  env_name="$1"
  repo_path="$2"

  if ! gh api --method PUT "repos/${repo_path}/environments/${env_name}" --silent; then
    format_error "Failed to create environment '${env_name}'"
    return 1
  fi
  format_success "Environment '${env_name}' created successfully."
}

remove_environment() {
  local env_name repo_path
  env_name="$1"
  repo_path="$2"

  if ! gh api "repos/${repo_path}/environments/${env_name}" -X DELETE --silent; then
    format_error "Failed to remove environment '${env_name}'"
    return 1
  fi
  format_success "Environment '${env_name}' removed successfully."
}

setup() {
  setup_colors
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  VERSION_FILE="${SCRIPT_DIR}/../../VERSION"
  SCRIPT_VERSION="unknown"
  if [[ -f "$VERSION_FILE" ]]; then
    SCRIPT_VERSION="$(< "$VERSION_FILE" tr -d '\n')"
  fi
  command_exists gh || {
    format_error "gh cli is not installed!"
    exit 1
  }
  command_exists jq || {
    format_error "jq is not installed!"
    exit 1
  }
}
main() {
  setup

  if [[ $# -lt 1 ]]; then
    usage
  fi
  local env_names arg remove_mode repo_path list_mode
  env_names=()
  remove_mode=0
  list_mode=0
  repo_path=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "${arg}" in
      -h|--help|help)
        usage
        ;;
      --version)
        print_version
        exit 0
        ;;
      --list)
        list_mode=1
        shift
        ;;
      --remove)
        remove_mode=1
        shift
        ;;
      --repo)
        shift
        if [[ $# -eq 0 ]]; then
          format_error "Missing value for --repo"
          usage
        fi
        repo_path="$1"
        shift
        ;;
      --*)
        format_error "Unknown flag: ${arg}"
        usage
        ;;
      -*)
        format_error "Invalid option: ${arg}"
        usage
        ;;
      *)
        env_names+=("${arg}")
        shift
        ;;
    esac
  done

  if [[ -z "${repo_path}" ]]; then
    # Get current repo in owner/repo format
    repo_path="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
    if [[ -z "${repo_path}" ]]; then
      format_error "Could not determine repository. Use --repo <owner/repo>."
      exit 1
    fi
  fi

  if [[ ${list_mode} -eq 1 ]]; then
    list_environments "${repo_path}"
    exit 0
  fi

  if [[ ${#env_names[@]} -eq 0 ]]; then
    usage
  fi

  for env_name in "${env_names[@]}"; do
    if [[ ${remove_mode} -eq 1 ]]; then
      remove_environment "${env_name}" "${repo_path}"
    else
      create_environment "${env_name}" "${repo_path}"
    fi
  done
}

main "$@"
