# GitHub Actions Repository Secrets Manager

A command-line tool for managing GitHub Actions secrets using the GitHub CLI (`gh`). Supports direct secret values, stdin input, and 1Password secret references for enhanced security.

## Description

This script provides a convenient interface to manage GitHub Actions repository secrets. It wraps the `gh secret` commands with additional features like 1Password integration, input validation, and user-friendly error messages.

## Features

- ✅ Add or update repository secrets
- 🗑️ Remove repository secrets
- 📋 List all repository secrets
- 🔐 1Password integration for secure secret retrieval
- 📥 Support for stdin input
- ✨ Input validation and error handling
- 🎨 Colored output with timestamps
- 📝 Comprehensive logging

## Requirements

### Required

- **Bash 4.0+**
- **GitHub CLI (`gh`)** - [Installation guide](https://cli.github.com/manual/installation)
  - Must be authenticated: `gh auth login`

### Optional

- **1Password CLI (`op`)** - Required only for 1Password secret references
  - [Installation guide](https://developer.1password.com/docs/cli/get-started/)
  - Must be authenticated: `op signin`

## Installation

1. Clone or download the script:

```bash
curl -o action-repo-secrets.sh https://raw.githubusercontent.com/psilore/toolbox/main/scripts/action-repo-secrets/action-repo-secrets.sh
chmod +x action-repo-secrets.sh
```

1. Ensure GitHub CLI is installed and authenticated:

```bash
gh auth login
```

## Usage

```bash
./action-repo-secrets.sh <command> [options]
```

### Commands

#### Add or Update a Secret

Add a secret with a direct value:

```bash
./action-repo-secrets.sh add owner/repo MY_SECRET "my_secret_value"
```

Add a secret using 1Password reference:

```bash
./action-repo-secrets.sh add owner/repo MY_SECRET "op://prod/github/token"
```

Add a secret from stdin:

```bash
echo "my_secret_value" | ./action-repo-secrets.sh add owner/repo MY_SECRET -
```

Read from a file:

```bash
./action-repo-secrets.sh add owner/repo SSH_KEY - < ~/.ssh/id_rsa
```

#### Remove a Secret

```bash
./action-repo-secrets.sh remove owner/repo MY_SECRET
```

#### List Secrets

```bash
./action-repo-secrets.sh list owner/repo
```

This shows all secret names (not values) with their last updated timestamps.

### Arguments

| Argument | Description |
|----------|-------------|
| `repo` | Repository in format `owner/repo` |
| `secret-name` | Name of the secret (uppercase recommended, e.g., `MY_SECRET`) |
| `secret-value` | Value of the secret. Can be:<br>• Direct value: `"my_value"`<br>• 1Password reference: `"op://vault/item/field"`<br>• Stdin: `-` |

## 1Password Integration

The script automatically detects 1Password secret references (format: `op://vault/item/field`) and retrieves the actual secret value using the 1Password CLI.

### 1Password Secret Reference Format

```shell
op://vault-name/item-name/field-name
```

- **vault-name**: The name of your 1Password vault
- **item-name**: The name of the item in the vault
- **field-name**: The field containing the secret value

### Examples using secret refrences in 1password vault

Store a GitHub token from 1Password:

```bash
./action-repo-secrets.sh add myorg/myrepo GITHUB_TOKEN "op://Production/GitHub/token"
```

Store an API key from 1Password:

```bash
./action-repo-secrets.sh add myorg/myrepo API_KEY "op://Secrets/API-Keys/production-key"
```

Store a database password:

```bash
./action-repo-secrets.sh add myorg/myrepo DB_PASSWORD "op://Production/Database/password"
```

### Benefits of 1Password Integration

1. **Centralized Secret Management**: Keep all secrets in 1Password
2. **Audit Trail**: 1Password tracks all secret access
3. **Team Collaboration**: Share vaults with team members
4. **Rotation Made Easy**: Update in 1Password, re-run script to update GitHub
5. **No Secrets in Command History**: References don't expose actual values

## Examples

### Basic Usage

```bash
# Add a simple secret
./action-repo-secrets.sh add octocat/hello-world API_TOKEN "ghp_abc123"

# List all secrets in a repository
./action-repo-secrets.sh list octocat/hello-world

# Remove a secret
./action-repo-secrets.sh remove octocat/hello-world API_TOKEN
```

### Advanced Usage

```bash
# Add multiple secrets from 1Password
./action-repo-secrets.sh add myorg/api PROD_DB_URL "op://prod/database/url"
./action-repo-secrets.sh add myorg/api PROD_DB_PASS "op://prod/database/password"
./action-repo-secrets.sh add myorg/api PROD_API_KEY "op://prod/api/key"

# Add a multiline secret (SSH key) from file
./action-repo-secrets.sh add myorg/deploy SSH_PRIVATE_KEY - < ~/.ssh/deploy_key

# Add a secret from environment variable
./action-repo-secrets.sh add myorg/app SECRET_VALUE "$MY_SECRET_VAR"

# Pipe secret from another command
aws secretsmanager get-secret-value --secret-id my-secret --query SecretString --output text | \
  ./action-repo-secrets.sh add myorg/app AWS_SECRET -
```

### Batch Operations

Create a script to set up all secrets for a repository:

```bash
#!/bin/bash
REPO="myorg/myrepo"

./action-repo-secrets.sh add "$REPO" GITHUB_TOKEN "op://prod/github/token"
./action-repo-secrets.sh add "$REPO" SLACK_WEBHOOK "op://prod/slack/webhook"
./action-repo-secrets.sh add "$REPO" AWS_ACCESS_KEY "op://prod/aws/access-key"
./action-repo-secrets.sh add "$REPO" AWS_SECRET_KEY "op://prod/aws/secret-key"

echo "✓ All secrets configured for $REPO"
```

### CI/CD Integration

Use in GitHub Actions workflow with [load secret action](https://github.com/marketplace/actions/load-secrets-from-1password) (requires 1Password service account):

```yaml
name: Configure Secrets

on:
  workflow_dispatch:

jobs:
  setup-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup 1Password CLI
        uses: 1password/load-secrets-action@v3
        with:
          export-env: false
      
      - name: Configure Repository Secrets
        run: |
          ./scripts/action-repo-secrets/action-repo-secrets.sh add \
            ${{ github.repository }} \
            DEPLOY_TOKEN \
            "op://prod/deploy/token"
```

## Output

The script provides timestamped, colored output:

```shell
Oct 12 10:15:23 [INFO]: Resolving 1Password secret reference: op://prod/github/token
Oct 12 10:15:24 [SUCCESS]: Secret GITHUB_TOKEN added successfully to myorg/myrepo
```

Error messages are clearly indicated:

```shell
Oct 12 10:15:25 [ERROR]: Invalid repository format. Use owner/repo
Oct 12 10:15:26 [ERROR]: Failed to read 1Password secret reference 'op://invalid/path': item not found
```

## Exit Codes

| Code | Description |
|------|-------------|
| `0` | Success |
| `1` | Error (validation failed, command failed, etc.) |

## Security Best Practices

1. **Never commit secrets**: Don't hardcode secret values in scripts
2. **Use 1Password references**: Keep actual secrets in 1Password, reference them in commands
3. **Limit repository access**: Use GitHub's repository access controls
4. **Rotate secrets regularly**: Update secrets in 1Password and re-run the script
5. **Use environment-specific vaults**: Separate prod/staging/dev secrets in different vaults
6. **Audit secret access**: Review 1Password audit logs regularly
7. **Use service accounts**: For automation, use 1Password service accounts with limited access

## Troubleshooting

### GitHub CLI not authenticated

```shell
Error: gh CLI is not installed. Please install it first.
```

**Solution**: Install and authenticate GitHub CLI:

```bash
gh auth login
```

### 1Password CLI not found

```shell
Error: 1Password CLI (op) is not installed. Please install it to use secret references.
```

**Solution**: Install 1Password CLI or use direct secret values instead of references.

### Invalid repository format

```shell
Error: Invalid repository format. Use owner/repo
```

**Solution**: Ensure repository is in `owner/repo` format (e.g., `octocat/hello-world`).

### Failed to read 1Password secret

```shell
Error: Failed to read 1Password secret reference 'op://...': [error details]
```

**Solutions**:

- Ensure you're signed in to 1Password: `op signin`
- Verify the vault/item/field path is correct
- Check you have access to the vault
- Confirm the item and field exist

### Permission denied

```shell
Error: Failed to add secret MY_SECRET
```

**Solutions**:

- Ensure you have admin access to the repository
- Check your GitHub token has the `repo` scope
- Verify the repository exists and you have write access

## Limitations

- Only manages repository-level secrets (not organization or environment secrets)
- Requires GitHub CLI to be installed and authenticated
- 1Password integration requires 1Password CLI and active session
- Secret values are not displayed (GitHub API limitation)

## Related Documentation

- [GitHub CLI Secret Commands](https://cli.github.com/manual/gh_secret)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [1Password CLI Secret References](https://developer.1password.com/docs/cli/secret-references/)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)

## License

This script is provided as-is for educational and practical use.  
Tailscale is a registered trademark of Tailscale Inc.  
1password is a registered trademark of 1password  Inc.  

## Contributing

Issues and pull requests are welcome at the [toolbox repository](https://github.com/psilore/toolbox).
