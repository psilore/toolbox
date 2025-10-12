# Toolbox

![toolbox](docs/images/toolbox.png)

[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![semantic-release: node](https://img.shields.io/badge/semantic--release-node-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)

A collection of utility scripts for managing GitHub repositories and workflows. This toolbox provides automation for common GitHub operations including secret management, environment setup, workflow monitoring, and repository administration through the GitHub CLI.

## Prerequisites

- [gh-cli](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)
- [1ppassword CLI](https://developer.1password.com/docs/cli/get-started/)

## Scripts

| Name | Description |
|--------|-------------|
| **action-repo-secrets** | Manage GitHub Actions repository secrets with support for direct values, stdin input, and 1Password integration |
| **job-conclusion** | Check workflow run conclusions and generate formatted deployment status reports |
| **manage-github** | Fetch GitHub repository names or team members for organizations and teams |
| **prepare-repo-environments** | Create, remove, and list GitHub Environments in repositories |

Usage

```bash
./path/to/script/<script-name>.sh --help
```

**Example**  

```bash
bash prepare-repo-environments/prepare-repo-environments.sh --help
```

```shell
scripts
├── action-repo-secrets
│   ├── action-repo-secrets.sh
│   └── README.md
├── job-conclusion
│   ├── job-conclusion.sh
│   └── README.md
├── manage-github
│   ├── manage-github.sh
│   └── README.md
└── prepare-repo-environments
    ├── prepare-repo-environments.sh
    └── README.md
```
