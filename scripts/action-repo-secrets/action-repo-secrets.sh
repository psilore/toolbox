#!/usr/bin/env bash
#
# Manage GitHub Actions secrets using gh CLI.
#
# This script provides functionality to add, remove, and list GitHub Actions
# secrets for repositories.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

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

#######################################
# Display usage information.
# Globals:
#   SCRIPT_NAME
# Arguments:
#   None
# Outputs:
#   Writes usage information to stdout
#######################################
usage() {
  cat << EOF

Usage: ${SCRIPT_NAME} <command> [options]

Options:
  --version, version   Show script version

Commands:
  add <repo> <secret-name> <secret-value>  Add or update a secret
  remove <repo> <secret-name>              Remove a secret
  list <repo>                              List all secrets

Arguments:
  repo          Repository in format owner/repo
  secret-name   Name of the secret (uppercase recommended)
  secret-value  Value of the secret (use - to read from stdin)
                Or use 1Password secret reference: op://vault/item/field

Examples:
  ${SCRIPT_NAME} add owner/repo MY_SECRET "secret_value"
  ${SCRIPT_NAME} add owner/repo MY_SECRET "op://prod/github/token"
  echo "secret_value" | ${SCRIPT_NAME} add owner/repo MY_SECRET -
  ${SCRIPT_NAME} remove owner/repo MY_SECRET
  ${SCRIPT_NAME} list owner/repo
  ${SCRIPT_NAME} --version

1Password Integration:
  If the secret value starts with "op://", it will be treated as a 1Password
  secret reference and the value will be retrieved using the 'op read' command.
  Requires 1Password CLI (op) to be installed and authenticated.

EOF
}

print_version() {
  echo "${SCRIPT_VERSION}"
}

#######################################
# Display error message and exit.
# Globals:
#   None
# Arguments:
#   Error message
# Outputs:
#   Writes error message to stderr
#######################################
error_exit() {
  format_error "$*"
  exit 1
}

#######################################
# Validate repository format.
# Arguments:
#   Repository string
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_repo() {
  local repo="$1"
  
  if [[ ! "${repo}" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
    return 1
  fi
  return 0
}

#######################################
# Check if gh CLI is installed.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if installed, exits if not
#######################################
check_gh_cli() {
  if ! command_exists gh; then
    error_exit "gh CLI is not installed. Please install it first."
  fi
}

#######################################
# Check if value is a 1Password secret reference.
# Arguments:
#   Value to check
# Returns:
#   0 if it's a 1Password reference, 1 if not
#######################################
is_op_reference() {
  local value="$1"
  [[ "${value}" =~ ^op:// ]]
}

#######################################
# Resolve 1Password secret reference.
# Arguments:
#   1Password secret reference (op://...)
# Outputs:
#   Secret value from 1Password
# Returns:
#   0 if successful, exits if not
#######################################
resolve_op_reference() {
  local reference="$1"
  
  if ! command_exists op; then
    error_exit "1Password CLI (op) is not installed. Please install it to use secret references."
  fi
  
  local value
  if ! value=$(op read "${reference}" 2>&1); then
    error_exit "Failed to read 1Password secret reference '${reference}': ${value}"
  fi
  
  echo "${value}"
}

#######################################
# Add or update a secret.
# Arguments:
#   Repository (owner/repo)
#   Secret name
#   Secret value or - for stdin or op:// reference
# Outputs:
#   Success or error message
#######################################
add_secret() {
  local repo="$1"
  local secret_name="$2"
  local secret_value="$3"
  
  if ! validate_repo "${repo}"; then
    error_exit "Invalid repository format. Use owner/repo"
  fi
  
  if [[ -z "${secret_name}" ]]; then
    error_exit "Secret name cannot be empty"
  fi
  
  if [[ "${secret_value}" == "-" ]]; then
    # Read from stdin
    if ! gh secret set "${secret_name}" -R "${repo}"; then
      error_exit "Failed to add secret ${secret_name}"
    fi
  else
    if [[ -z "${secret_value}" ]]; then
      error_exit "Secret value cannot be empty"
    fi
    
    # Check if it's a 1Password reference
    if is_op_reference "${secret_value}"; then
      format_log "Resolving 1Password secret reference: ${secret_value}"
      secret_value=$(resolve_op_reference "${secret_value}")
    fi
    
    if ! gh secret set "${secret_name}" -R "${repo}" --body "${secret_value}"; then
      error_exit "Failed to add secret ${secret_name}"
    fi
  fi
  
  format_success "Secret ${secret_name} added successfully to ${repo}"
}

#######################################
# Remove a secret.
# Arguments:
#   Repository (owner/repo)
#   Secret name
# Outputs:
#   Success or error message
#######################################
remove_secret() {
  local repo="$1"
  local secret_name="$2"
  
  if ! validate_repo "${repo}"; then
    error_exit "Invalid repository format. Use owner/repo"
  fi
  
  if [[ -z "${secret_name}" ]]; then
    error_exit "Secret name cannot be empty"
  fi
  
  if ! gh secret delete "${secret_name}" -R "${repo}"; then
    error_exit "Failed to remove secret ${secret_name}"
  fi
  
  format_success "Secret ${secret_name} removed successfully from ${repo}"
}

#######################################
# List all secrets.
# Arguments:
#   Repository (owner/repo)
# Outputs:
#   List of secrets
#######################################
list_secrets() {
  local repo="$1"
  
  if ! validate_repo "${repo}"; then
    error_exit "Invalid repository format. Use owner/repo"
  fi
  
  if ! gh secret list -R "${repo}"; then
    error_exit "Failed to list secrets for ${repo}"
  fi
}

setup() {
  setup_colors
  check_gh_cli
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  VERSION_FILE="${SCRIPT_DIR}/../../VERSION"
  SCRIPT_VERSION="unknown"
  if [[ -f "$VERSION_FILE" ]]; then
    SCRIPT_VERSION="$(< "$VERSION_FILE" tr -d '\n')"
  fi
}

#######################################
# Main function.
# Arguments:
#   Command line arguments
# Outputs:
#   Depends on command
#######################################
main() {
  setup
  
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi
  
  local command="$1"
  shift
  
  case "${command}" in
    --version|version)
      print_version
      exit 0
      ;;
    add)
      if [[ $# -ne 3 ]]; then
        format_error "add requires 3 arguments"
        usage
        exit 1
      fi
      add_secret "$1" "$2" "$3"
      ;;
    remove)
      if [[ $# -ne 2 ]]; then
        format_error "remove requires 2 arguments"
        usage
        exit 1
      fi
      remove_secret "$1" "$2"
      ;;
    list)
      if [[ $# -ne 1 ]]; then
        format_error "list requires 1 argument"
        usage
        exit 1
      fi
      list_secrets "$1"
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      format_error "Unknown command '${command}'"
      usage
      exit 1
      ;;
  esac
}

main "$@"
