#!/usr/bin/env bash

# Script to fetch GitHub repository names or team members using the gh CLI.

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

format_warning() {
  _format_msg "${FMT_YELLOW}${FMT_BOLD}" "WARNING" "$@"
}

format_success() {
  _format_msg "${FMT_GREEN}${FMT_BOLD}" "SUCCESS" "$@"
}

format_log() {
  _format_msg "${FMT_BOLD}" "INFO" "$@"
}

setup_colors(){
  FMT_GREEN=$(printf '\033[32m')
  FMT_YELLOW=$(printf '\033[33m')
  FMT_RED=$(printf '\033[31m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

get_repo_names() {
  local url

  if [ -n "$OWNER" ] && [ -z "$TEAM_SLUG" ]; then
    url="users/$OWNER/repos"
  elif [ -n "$OWNER" ] && [ -n "$TEAM_SLUG" ]; then
    url="orgs/$OWNER/teams/$TEAM_SLUG/repos"
  else
    format_error "OWNER must be provided."
    exit 1
  fi
  fetch_repo_names "$url"
}

fetch_repo_names() {
  local url="$1"
  local active_repos
  local repo_names

  if ! active_repos=$(gh api "$url" --paginate 2>&1); then
    format_error "Failed to fetch data from GitHub API:"
    echo "$active_repos"
    exit 1
  fi

  if ! repo_names=$(echo "$active_repos" | jq -r '.[].name' 2>&1); then
    format_error "Failed to parse JSON with jq:"
    format_log "$repo_names"
    exit 1
  fi

  echo "$repo_names"
}

get_team_members() {
  local url
  local members
  if [ -z "$OWNER" ]; then
    format_error "OWNER must be provided."
    exit 1
  fi
  if [ -z "$TEAM_SLUG" ]; then
    url="/orgs/$OWNER/members"
  else
    url="/orgs/$OWNER/teams/$TEAM_SLUG/members"
  fi
  if ! members=$(gh api "$url" --paginate 2>&1); then
    format_error "Failed to fetch members from GitHub API:"
    echo "$members"
    exit 1
  fi
  echo "$members" | jq -r '.[].login'
}

print_version() {
  echo "$SCRIPT_VERSION"
}

usage() {
  printf '%s\n' "${FMT_BOLD}Usage:${FMT_RESET} bash $(dirname "$0")/$(basename "$0") [OPTIONS]"
  printf '%s\n' "  --version                 Show script version"
  printf '\n'
  printf '%s\n' "${FMT_BOLD}Options:${FMT_RESET}"
  printf '\n'
  printf '%s\n' "  -h, --help                                 Show this help message"
  printf '%s\n' "  -m, --members OWNER [Required],TEAM_SLUG   Get members of the team for the owner or team (comma or space separated)"
  printf '%s\n' "  -r, --repos OWNER [Required],TEAM_SLUG     Get repositories for the owner or team (comma or space separated)"
  printf '\n'
  printf '%s\n' "Examples:"
  printf '%s\n' "  bash $(dirname "$0")/$(basename "$0") -r acme              List repos for user/organization acme"
  printf '%s\n' "  bash $(dirname "$0")/$(basename "$0") -r acme,dreamteam    List repos in organization acme for team dreamteam"
  printf '%s\n' "  bash $(dirname "$0")/$(basename "$0") -m acme              List members of organization acme"
  printf '%s\n' "  bash $(dirname "$0")/$(basename "$0") -m acme,dreamteam    List members in organization acme for team dreamteam"
  printf '\n'
}


setup() {
  setup_colors
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  VERSION_FILE="${SCRIPT_DIR}/../../VERSION"
  SCRIPT_VERSION="unknown"
  if [[ -f "$VERSION_FILE" ]]; then
    SCRIPT_VERSION="$(< "$VERSION_FILE" tr -d '\n')"
  fi
  command_exists git || {
    format_error "git is not installed!"
    exit 1
  }
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
  if [[ "$1" == "--version" ]]; then
    print_version
    exit 0
  fi
  if ! OPTIONS=$(getopt -o hr:m: --long help,repos:,members: -- "$@"); then
    usage
    exit 1
  fi
  eval set -- "$OPTIONS"
  REPOS_FLAG=false
  MEMBERS_FLAG=false
  while true; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -m|--members)
        if [[ "$2" == *,* ]]; then
          IFS=',' read -r OWNER TEAM_SLUG <<< "$2"
        else
          OWNER="$2"
          if [ -n "$3" ] && [[ "$3" != -* ]]; then
            TEAM_SLUG="$3"
            shift
          else
            TEAM_SLUG=""
          fi
        fi
        MEMBERS_FLAG=true
        shift 2
        ;;
      -r|--repos)
        if [[ "$2" == *,* ]]; then
          IFS=',' read -r OWNER TEAM_SLUG <<< "$2"
        else
          OWNER="$2"
          if [ -n "$3" ] && [[ "$3" != -* ]]; then
            TEAM_SLUG="$3"
            shift
          else
            TEAM_SLUG=""
          fi
        fi
        REPOS_FLAG=true
        shift 2
        ;;
      --)
        shift
        break
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  done

  # If no valid option was passed, print usage and exit 1
  if [ "$MEMBERS_FLAG" = false ] && [ "$REPOS_FLAG" = false ]; then
    usage
    exit 1
  fi

  if [ "$MEMBERS_FLAG" = true ]; then
    get_team_members
    exit 0
  fi

  if [ "$REPOS_FLAG" = true ]; then
    get_repo_names
    exit 0
  fi

}

main "$@"