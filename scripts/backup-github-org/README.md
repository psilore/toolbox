# GitHub Organization Backup Script

A bash script to backup all repositories from a GitHub organization as mirror clones, with optional metadata backup.

## Description

This script fetches all repositories from a specified GitHub organization and creates mirror backups of each repository. Optionally, it can also backup issues, pull requests, reviews, comments, and releases. The backups are then compressed into a timestamped tar.gz archive for easy storage and transfer.

## Features

- 🔄 Fetches all repositories from a GitHub organization using the GitHub API
- 📦 Creates mirror clones preserving all branches, tags, and refs
- 📝 Optional backup of issues, pull requests, and releases metadata
- 💬 Optional backup of PR reviews and comments history
- 🗜️ Compresses backups into a timestamped tar.gz archive
- 🎨 Colored output with timestamps for better readability
- ✅ Validates required dependencies before execution
- 🧹 Automatic cleanup of temporary backup directory
- 🏷️ Version information display

## Prerequisites

The following tools must be installed on your system:

- `git` - For cloning repositories
- `gh` - GitHub CLI (authenticated)
- `jq` - JSON processor
- `curl` - HTTP client
- `tar` - Archive utility
- `bash` 4.0+ - Shell interpreter

## Installation

1. Clone this repository or download the script
2. Make the script executable:

   ```bash
   chmod +x backup-github-org.sh
   ```

3. Ensure you're authenticated with GitHub CLI:

   ```bash
   gh auth login
   ```

## Usage

### Basic Usage

```bash
./backup-github-org.sh -o <organization-name>
```

### Options

| Option              | Description                                 |
| ------------------- | ------------------------------------------- |
| `-o, --owner OWNER` | GitHub organization name (required)         |
| `-m, --metadata`    | Backup issues, PRs, and releases (optional) |
| `-r, --history`     | Backup PR reviews and comments (optional)   |
| `-h, --help`        | Show help message                           |
| `--version`         | Show script version                         |

### Examples

Backup only repositories (mirror clones):

```bash
./backup-github-org.sh -o myorg
```

Backup repositories with metadata (issues, PRs, releases):

```bash
./backup-github-org.sh -o myorg -m
```

Backup repositories with metadata and PR history (reviews, comments):

```bash
./backup-github-org.sh -o myorg -m -r
```

Using long option format:

```bash
./backup-github-org.sh --owner myorg --metadata --history
```

Show help:

```bash
./backup-github-org.sh --help
```

Show version:

```bash
./backup-github-org.sh --version
```

## Output

The script creates a compressed archive with the naming format:

```shell
gh-org-backup-YYYY-MM-DD-HH-MM-SS.tar.gz
```

This archive contains mirror clones of all repositories from the specified organization, and optionally metadata in JSON format.

### Example Output

```shell
Oct 15 10:10:20 [INFO]: Fetching repositories for organization: myorg
Oct 15 10:10:21 [INFO]: Cloning repository: repo1
Oct 15 10:10:28 [SUCCESS]: Successfully cloned repo1
Oct 15 10:10:28 [INFO]: Backing up issues for repo1...
Oct 15 10:10:29 [INFO]: Backing up pull requests for repo1...
Oct 15 10:10:30 [INFO]: Backing up pull request reviews for repo1...
Oct 15 10:10:31 [INFO]: Backing up issue comments for repo1...
Oct 15 10:10:32 [INFO]: Backing up releases for repo1...
Oct 15 10:15:22 [SUCCESS]: Backup completed in 307 seconds.
```

## How It Works

1. **Validation**: Checks for required dependencies
2. **Fetch**: Retrieves list of all repositories from the organization using GitHub API
3. **Clone**: Creates mirror clones of each repository
4. **Metadata Backup** (if `-m` flag used):
   - Fetches all issues (excluding PRs)
   - Fetches all pull requests (all states: open, closed, merged)
   - Fetches issue comments
   - Fetches releases
5. **History Backup** (if `-r` flag used):
   - Fetches PR reviews for each pull request
   - Fetches PR comments for each pull request
6. **Compress**: Archives all clones and metadata into a timestamped tar.gz file
7. **Cleanup**: Removes temporary backup directory

## Backup Structure

### Repository Mirror Clones

The mirror clones preserve:

- All branches
- All tags
- All refs
- Complete commit history
- Repository metadata

### Metadata Files (when using `-m` flag)

For each repository, a `<repo>-metadata/` directory is created containing:

- `issues.json` - All issues (excluding pull requests)
- `pull_requests.json` - All pull requests with all states
- `issue_comments.json` - All issue comments
- `releases.json` - All releases

### History Files (when using `-r` flag)

**Note!**  

This could increase disk usage, depending on how much activity in each repository.
Always review if this option is needed.

Additional files in the metadata directory:

- `pr_<number>_reviews.json` - Reviews for each pull request
- `pr_<number>_comments.json` - Comments for each pull request

### Archive Structure Example

```shell
gh-org-backup-2024-10-15-10-10-20.tar.gz
├── repo1.git/                    # Mirror clone
├── repo1-metadata/               # Metadata (if -m used)
│   ├── issues.json
│   ├── pull_requests.json
│   ├── issue_comments.json
│   └── releases.json
├── repo-1-pr-history             # PR history (if -r used)
│   ├── pr_1_reviews.json
│   ├── pr_1_comments.json
│   └── ...
├── repo2.git/
├── repo2-metadata/
└── ...
```

## Troubleshooting

### Authentication Error

If you see an error about GitHub CLI not being authenticated:

```bash
gh auth login
```

### Permission Denied

If the organization is private, ensure your GitHub account has access and the `gh` CLI is authenticated with appropriate permissions.

### Missing Dependencies

The script will check for all required dependencies and report which ones are missing. Install any missing tools before running the script.

### Rate Limiting

When backing up metadata for organizations with many repositories or PRs, you may encounter GitHub API rate limits. The script will show errors for failed API calls but will continue processing other repositories.

## Security Considerations

- The script requires GitHub CLI authentication with read access to the organization
- Backup archives contain full repository data including all history
- Metadata backups include issue and PR content which may contain sensitive information,
  but best practices is not to add sensitive data to repos!
- Store backup archives securely as they may contain sensitive code and discussions

## Notes

- Large organizations with many repositories may take significant time to backup
- Using `-m` and `-r` flags significantly increases backup time and size
- Ensure you have sufficient disk space for clones, metadata, and the compressed archive
- The backup includes only repository data and metadata, not organization settings
- PR history backup (`-r`) requires the `-m` flag to be useful, as it depends on metadata being present

## Performance Considerations

- **Code only** (`-o myorg`): Fastest, smallest backup
- **Code + metadata** (`-o myorg -m`): Moderate speed, includes issues/PRs/releases
- **Code + metadata + history** (`-o myorg -m -r`): Slowest, most comprehensive backup

## License

See the main repository [LICENSE](../../LICENSE) file.

## Contributing

Contributions are welcome! Please submit issues and pull requests to the main repository.
