#!/usr/bin/env bash

# This script will backup github organization.

set -euo pipefail

#######################################
# Check if command exists.
# Arguments:
#   Command name
# Returns:
#   0 if exists, 1 if not
#######################################
command_exists() {
  command -v "$@" >/dev/null 2>&1
}

#######################################
# Format message with color and timestamp.
# Arguments:
#   $1 - color code
#   $2 - level label
#   $3+ - message
# Outputs:
#   Formatted message to stderr
#######################################
_format_msg() {
  # $1=color, $2=level, $3=message
  local color="$1"
  local level="$2"
  shift 2
  local date
  date="$(date +"%b %d %H:%M:%S")"
  printf "%s%s [%s]: %s%s\n" "$color" "$date" "$level" "$*" "$FMT_RESET" >&2
}

#######################################
# Format error message.
# Arguments:
#   Error message
# Outputs:
#   Formatted error to stderr
#######################################
format_error() {
  _format_msg "${FMT_RED}${FMT_BOLD}" "ERROR" "$@"
}

#######################################
# Format success message.
# Arguments:
#   Success message
# Outputs:
#   Formatted success to stderr
#######################################
format_success() {
  _format_msg "${FMT_GREEN}${FMT_BOLD}" "SUCCESS" "$@"
}

#######################################
# Format info message.
# Arguments:
#   Info message
# Outputs:
#   Formatted info to stderr
#######################################
format_log() {
  _format_msg "${FMT_BOLD}" "INFO" "$@"
}

#######################################
# Setup color formatting codes.
# Globals:
#   FMT_GREEN, FMT_RED, FMT_RESET, FMT_BOLD
# Arguments:
#   None
#######################################
setup_colors() {
  FMT_GREEN=$(printf '\033[32m')
  FMT_RED=$(printf '\033[31m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

get_repo_names() {
  local URL
  local ACTIVE_REPOS
  local REPO_NAMES

  URL="orgs/$OWNER/repos"
  
  format_log "Fetching repositories for organization: $OWNER"
  
  if ! ACTIVE_REPOS=$(gh api "$URL" --paginate 2>&1); then
    format_error "Failed to fetch data from GitHub API:"
    format_log "$ACTIVE_REPOS"
    exit 1
  fi

  if ! REPO_NAMES=$(echo "$ACTIVE_REPOS" | jq -r '.[].name' 2>&1); then
    format_error "Failed to parse JSON with jq:"
    format_log "$REPO_NAMES"
    exit 1
  fi

  mapfile -t REPOS_ARRAY <<< "$REPO_NAMES"
}

# Add new function to backup issues and PRs
#######################################
# Backup issues and pull requests for a repository.
# Arguments:
#   $1 - repository name
# Outputs:
#   JSON files with issues and PRs data
#######################################
backup_repo_metadata() {
  local repo_name="$1"
  local metadata_dir="$BACKUP_DIR/$repo_name-metadata"
  
  mkdir -p "$metadata_dir"
  
  format_log "Backing up issues for $repo_name..."
  if ! gh api "repos/$OWNER/$repo_name/issues" --paginate --jq '.[] | select(.pull_request == null)' > "$metadata_dir/issues.json" 2>&1; then
    format_error "Failed to backup issues for $repo_name"
  fi
  
  format_log "Backing up pull requests for $repo_name..."
  if ! gh api "repos/$OWNER/$repo_name/pulls?state=all" --paginate --jq '.' > "$metadata_dir/pull_requests.json" 2>&1; then
    format_error "Failed to backup pull requests for $repo_name"
  fi

  format_log "Backing up issue comments for $repo_name..."
  if ! gh api "repos/$OWNER/$repo_name/issues/comments" --paginate > "$metadata_dir/issue_comments.json" 2>&1; then
    format_error "Failed to backup issue comments for $repo_name"
  fi
  
  format_log "Backing up releases for $repo_name..."
  if ! gh api "repos/$OWNER/$repo_name/releases" --paginate > "$metadata_dir/releases.json" 2>&1; then
    format_error "Failed to backup releases for $repo_name"
  fi
}

backup_repo_history() {
  local repo_name="$1"
  local history_dir="$BACKUP_DIR/$repo_name-pr-history"

  mkdir -p "$history_dir"

  format_log "Backing up pull request reviews for $repo_name..."
  local pr_numbers
  pr_numbers=$(gh api "repos/$OWNER/$repo_name/pulls?state=all" --paginate --jq '.[].number')
  
  for pr_num in $pr_numbers; do
    gh api "repos/$OWNER/$repo_name/pulls/$pr_num/reviews" --paginate > "$history_dir/pr_${pr_num}_reviews.json" 2>/dev/null || true
    gh api "repos/$OWNER/$repo_name/pulls/$pr_num/comments" --paginate > "$history_dir/pr_${pr_num}_comments.json" 2>/dev/null || true
  done
}

backup_repos() {
  START_TIME=$(date +%s)

  mkdir -p "$BACKUP_DIR"

  for REPO_NAME in "${REPOS_ARRAY[@]}"; do
    repo_url="https://github.com/$OWNER/$REPO_NAME.git"
    format_log "Cloning repository: $REPO_NAME"

    if ! cd "$BACKUP_DIR"; then
      format_error "Failed to change to backup directory"
      continue
    fi

    if git clone --mirror "$repo_url"; then
      format_success "Successfully cloned $REPO_NAME"
      
      if [[ "${BACKUP_METADATA}" == "true" ]]; then
        backup_repo_metadata "$REPO_NAME"
      fi

      if [[ "${BACKUP_HISTORY}" == "true" ]]; then
        backup_repo_history "$REPO_NAME"
      fi
    else
      format_error "Failed to clone $REPO_NAME"
    fi
  done
  
  format_log "Creating compressed archive..."
  tar -czvf "$SCRIPT_DIR/gh-org-backup-$DATE_NOW.tar.gz" -C "$BACKUP_DIR" .

  rm -rf "$BACKUP_DIR"
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))
  format_success "Backup completed in $DURATION seconds."
}

#######################################
# Display usage information.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes usage to stdout
#######################################
usage() {
  cat <<EOF
${FMT_BOLD}Usage:${FMT_RESET} $(basename "$0") [OPTIONS]

Backup a GitHub organization's repositories.

${FMT_BOLD}Options:${FMT_RESET}
  -o, --owner OWNER        GitHub organization name (required)
  -m, --metadata           Backup issues, PRs, and releases (optional)
  -r, --history            Backup PR reviews and comments (optional)
  -h, --help               Show this help message
  --version                Show script version

${FMT_BOLD}Notes:${FMT_RESET}
  Enabling --metadata and --history may increase backup time and storage requirements.
  Make sure you have enough disk space before proceeding. Depending on the size of the organization,
  this process may take a considerable amount of time.

${FMT_BOLD}Examples:${FMT_RESET}
  $(basename "$0") -o myorg
  $(basename "$0") --owner myorg --metadata
  $(basename "$0") --owner myorg --metadata --history

EOF
  exit 0
}

cleanup() {
  format_log "Cleaning up backup directory: $BACKUP_DIR"
  rm -rf "$BACKUP_DIR"
}

print_version() {
  echo "${SCRIPT_VERSION}"
}

setup() {
  setup_colors

  command_exists git || {
    format_error "git is not installed"
    exit 1
  }

  command_exists curl || {
    format_error "curl is not installed"
    exit 1
  }

  command_exists jq || {
    format_error "jq is not installed"
    exit 1
  }

  command_exists gh || {
    format_error "gh cli is not installed"
    exit 1
  }

  command_exists tar || {
    format_error "tar is not installed"
    exit 1
  }


  DATE_NOW="$(date +"%Y-%m-%d-%H-%M-%S")"
  SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
  SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
  VERSION_FILE="${SCRIPT_DIR}/../../VERSION"
  SCRIPT_VERSION="unknown"
  if [[ -f "$VERSION_FILE" ]]; then
    SCRIPT_VERSION="$(< "$VERSION_FILE" tr -d '\n')"
  fi
  BACKUP_DIR="$SCRIPT_DIR/backups"

  REPOS_ARRAY=()
}

main() {
  setup
  
  # Parse command line arguments
  OWNER=""
  BACKUP_METADATA="false"
  BACKUP_HISTORY="false"
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--owner)
        if [[ -z "${2:-}" ]]; then
          format_error "Option --owner requires an argument"
          usage
        fi
        OWNER="$2"
        shift 2
        ;;
      -m|--metadata)
        BACKUP_METADATA="true"
        shift
        ;;
      -r|--history)
        BACKUP_HISTORY="true"
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
        format_error "Unknown option: $1"
        usage
        ;;
    esac
  done
  
  # Validate required arguments
  if [[ -z "$OWNER" ]]; then
    format_error "Organization name is required"
    usage
  fi
  
  get_repo_names
  backup_repos
  cleanup
}

main "$@"