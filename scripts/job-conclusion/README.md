# Job Conclusion

A GitHub Actions utility script that checks workflow run conclusions and reports deployment results.

## Description

This script monitors the conclusion status of a GitHub Actions workflow run and provides formatted reporting. It's designed to be used in GitHub Actions workflows, particularly for deployment pipelines where you need to track and report on the success or failure of dependent workflows.

## Features

- ✅ Checks workflow run conclusion status
- 📊 Generates formatted GitHub Step Summary on failure (or outputs to stdout)
- 🔗 Provides direct links to failed workflow runs
- 🎯 Designed for deployment monitoring workflows
- 📝 Flexible output modes: file or stdout
- 🏷️ Version information display

## Installation

1. Ensure the script is executable:
   ```bash
   chmod +x scripts/job-conclusion/job-conclusion.sh
   ```

2. The script requires a `VERSION` file in the repository root

## Usage

### Command Line Options

```bash
./job-conclusion.sh [OPTIONS]
```

| Option         | Description                                     |
| -------------- | ----------------------------------------------- |
| `-f, --file`   | Write summary to step_summary.md file (default) |
| `-l, --log`    | Output summary to stdout instead of file        |
| `-h, --help`   | Show help message                               |
| `--version`    | Show script version                             |

### Examples

Write to file (default):
```bash
./job-conclusion.sh
./job-conclusion.sh --file
```

Output to stdout:
```bash
./job-conclusion.sh --log
```

Show version:
```bash
./job-conclusion.sh --version
```

Show help:
```bash
./job-conclusion.sh --help
```

### In GitHub Actions Workflow

#### Default Usage (Write to File)

```yaml
name: Deployment Monitor

on:
  workflow_run:
    workflows: ["Deploy to Production"]
    types:
      - completed

jobs:
  check-deployment:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Check Workflow Conclusion
        env:
          GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION: ${{ github.event.workflow_run.conclusion }}
          GITHUB_EVENT_REPOSITORY_NAME: ${{ github.event.repository.name }}
          GITHUB_EVENT_WORKFLOW_RUN_HTML_URL: ${{ github.event.workflow_run.html_url }}
          GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER: ${{ github.event.workflow_run.run_number }}
          DEPLOYMENT_ENVIRONMENT: production  # Optional: customize environment name
          WORKFLOW_NAME: Deploy to Production  # Optional: customize workflow display name
        run: ./scripts/job-conclusion/job-conclusion.sh
```

#### Using Stdout Output

```yaml
      - name: Check Workflow Conclusion
        env:
          GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION: ${{ github.event.workflow_run.conclusion }}
          GITHUB_EVENT_REPOSITORY_NAME: ${{ github.event.repository.name }}
          GITHUB_EVENT_WORKFLOW_RUN_HTML_URL: ${{ github.event.workflow_run.html_url }}
          GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER: ${{ github.event.workflow_run.run_number }}
          DEPLOYMENT_ENVIRONMENT: production
        run: ./scripts/job-conclusion/job-conclusion.sh --log
```

#### Using GitHub Context

The workflow_run event provides the workflow name automatically:

```yaml
      - name: Check Workflow Conclusion
        env:
          GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION: ${{ github.event.workflow_run.conclusion }}
          GITHUB_EVENT_REPOSITORY_NAME: ${{ github.event.repository.name }}
          GITHUB_EVENT_WORKFLOW_RUN_HTML_URL: ${{ github.event.workflow_run.html_url }}
          GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER: ${{ github.event.workflow_run.run_number }}
          GITHUB_EVENT_WORKFLOW_RUN_NAME: ${{ github.event.workflow_run.name }}
          DEPLOYMENT_ENVIRONMENT: production  # Must be set manually - not available in workflow_run event
        run: ./scripts/job-conclusion/job-conclusion.sh
```

**Note:** The workflow_run event does NOT include environment information. You must set `DEPLOYMENT_ENVIRONMENT` manually based on your workflow setup.

### Custom Environment Example

```yaml
      - name: Check Staging Deployment
        env:
          GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION: ${{ github.event.workflow_run.conclusion }}
          GITHUB_EVENT_REPOSITORY_NAME: ${{ github.event.repository.name }}
          GITHUB_EVENT_WORKFLOW_RUN_HTML_URL: ${{ github.event.workflow_run.html_url }}
          GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER: ${{ github.event.workflow_run.run_number }}
          DEPLOYMENT_ENVIRONMENT: staging
          WORKFLOW_NAME: Deploy to Staging
        run: ./scripts/job-conclusion/job-conclusion.sh
```

### Environment Variables

The script uses the following environment variables (typically set automatically by GitHub Actions):

| Variable                               | Description                                                                  | Required | Default                                                        |
| -------------------------------------- | ---------------------------------------------------------------------------- | -------- | -------------------------------------------------------------- |
| `GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION` | The conclusion of the workflow run (`success`, `failure`, `cancelled`, etc.) | Yes      | -                                                              |
| `GITHUB_EVENT_REPOSITORY_NAME`         | Repository name                                                              | No       | -                                                              |
| `GITHUB_EVENT_WORKFLOW_RUN_HTML_URL`   | URL to the workflow run                                                      | No       | -                                                              |
| `GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER` | Workflow run number                                                          | No       | -                                                              |
| `GITHUB_EVENT_WORKFLOW_RUN_NAME`       | Workflow name from the workflow run event                                    | No       | -                                                              |
| `DEPLOYMENT_ENVIRONMENT`               | Deployment environment name (e.g., `prod`, `staging`, `dev`)                 | No       | `prod`                                                         |
| `WORKFLOW_NAME`                        | Workflow display name for the summary                                        | No       | Falls back to `GITHUB_EVENT_WORKFLOW_RUN_NAME` or `deploy.yml` |

## Output

### Output Modes

The script supports two output modes:

1. **File mode (default)**: Writes summary to `step_summary.md` and validates the file
2. **Stdout mode**: Outputs summary directly to stdout (useful for debugging or logging)

### Success Case

When the workflow conclusion is `success`:

- Prints: `[SUCCESS]: Workflow succeeded`
- Exits with code `0`

### Failure Case

When the workflow conclusion is anything other than `success`:

- Prints: `[ERROR]: Workflow failed`
- Generates a formatted summary (to file or stdout depending on mode)
- Exits with code `1`

### Step Summary Format

On failure, the script creates a formatted table:

```markdown
### 🚫 Deployment Failed!

**See job:**
| Name      | Workflow                                       | Run ID | Environment |
| --------- | ---------------------------------------------- | ------ | ----------- |
| repo-name | [Deploy to Production](https://github.com/...) | 123    | production  |
```

### File Mode Validation

When using file mode (default), the script validates that:
- The `step_summary.md` file exists
- The file contains the expected table header
- The file contains at least one valid summary row

Validation failures result in specific exit codes:
- Exit code `10`: File does not exist
- Exit code `11`: Table header not found
- Exit code `12`: No valid summary row found

## Configuration

### Environment Name (Manual Configuration Required)

The workflow_run event does NOT include environment information. You must set the `DEPLOYMENT_ENVIRONMENT` variable explicitly:

```yaml
env:
  DEPLOYMENT_ENVIRONMENT: production  # or staging, dev, etc.
```

**Why?** GitHub's workflow_run event payload doesn't expose which environment the workflow ran in. The `environment` context is only available within the job that declares the environment, not in dependent workflows listening to workflow_run events.

Default: `prod`

### Workflow Name (Auto-detected)

The workflow name is automatically detected from `${{ github.event.workflow_run.name }}`. You can override it:

```yaml
env:
  WORKFLOW_NAME: "Custom Workflow Name"
```

Priority order:

1. `WORKFLOW_NAME` (explicit override)
2. `GITHUB_EVENT_WORKFLOW_RUN_NAME` (from workflow run event)
3. Default: `deploy.yml`

### Output Mode

Control where the summary is written:

```yaml
# Write to file (default)
run: ./scripts/job-conclusion/job-conclusion.sh

# Write to file (explicit)
run: ./scripts/job-conclusion/job-conclusion.sh --file

# Output to stdout
run: ./scripts/job-conclusion/job-conclusion.sh --log
```

## Exit Codes

- `0` - Workflow concluded successfully
- `1` - Workflow failed or had a non-success conclusion
- `10` - File mode: step_summary.md does not exist
- `11` - File mode: Table header not found in step_summary.md
- `12` - File mode: No valid summary row found in step_summary.md

## Example Scenarios

### Monitoring Deployment Workflows

Use this script to monitor deployment workflows and get notified when deployments fail:

```yaml
on:
  workflow_run:
    workflows: ["Deploy to Production"]
    types: [completed]
```

### Debugging with Stdout

When debugging or testing, use stdout mode to see the summary output directly:

```yaml
      - name: Debug Workflow Conclusion
        env:
          GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION: failure
          GITHUB_EVENT_REPOSITORY_NAME: my-repo
          DEPLOYMENT_ENVIRONMENT: dev
        run: ./scripts/job-conclusion/job-conclusion.sh --log
```

### In a Job with Environment Declaration

If you're using the script within a job that declares an environment:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # GitHub environment
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Deploy
        run: ./deploy.sh
      
      - name: Check Result
        if: always()
        env:
          GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION: ${{ job.status }}
          DEPLOYMENT_ENVIRONMENT: ${{ environment.name }}  # Auto-populated from environment declaration
          WORKFLOW_NAME: ${{ github.workflow }}
        run: ./scripts/job-conclusion/job-conclusion.sh
```

Note: The `environment.name` context is only available when the job declares an `environment`.

### Checking Multiple Workflow Conclusions

Monitor different deployment environments with custom configurations:

```yaml
jobs:
  check-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check Production
        env:
          DEPLOYMENT_ENVIRONMENT: production
          WORKFLOW_NAME: Production Deployment
        run: ./scripts/job-conclusion/job-conclusion.sh

  check-staging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check Staging
        env:
          DEPLOYMENT_ENVIRONMENT: staging
          WORKFLOW_NAME: Staging Deployment
        run: ./scripts/job-conclusion/job-conclusion.sh
```

## Requirements

- Bash 4.0 or later
- GitHub Actions environment (for file mode with step summaries)
- `VERSION` file in repository root (for version command)

## Notes

- **Environment must be set manually** via `DEPLOYMENT_ENVIRONMENT` (defaults to `prod`)
- The workflow name is auto-detected from `${{ github.event.workflow_run.name }}` (defaults to `deploy.yml`)
- The script is specifically designed for the `workflow_run` trigger
- File validation only runs in file mode (not when using `--log`)

### Why No Auto-Detection for Environment?

GitHub's `workflow_run` event payload does **not** include environment information. The `environment` context is only available within a job that has an `environment:` declaration, and this information is not passed to dependent workflows.

**Workarounds:**

1. Set `DEPLOYMENT_ENVIRONMENT` manually based on your workflow setup
2. Encode environment in workflow names (e.g., "Deploy Production", "Deploy Staging")  
3. Use matrix strategy to run checks for multiple environments with different `DEPLOYMENT_ENVIRONMENT` values

### Available GitHub Context

**In workflow_run events:**

- ✅ `${{ github.event.workflow_run.name }}` - workflow name
- ✅ `${{ github.event.workflow_run.conclusion }}` - workflow conclusion
- ✅ `${{ github.event.workflow_run.html_url }}` - workflow URL
- ❌ `${{ github.event.workflow_run.environment }}` - **NOT AVAILABLE**

**In jobs with environment declaration:**

- ✅ `${{ environment.name }}` - only when job has `environment:` key
- ❌ Not accessible from workflow_run events

## Troubleshooting

### File Not Created in File Mode

If you see exit code `10`, the `step_summary.md` file was not created. This can happen if:

- The script doesn't have write permissions
- The disk is full
- There's an error in the setup function

**Solution**: Check file permissions and disk space, or use `--log` mode for debugging.

### Invalid Summary Format

If you see exit codes `11` or `12`, the summary file was created but doesn't contain the expected format. This indicates a bug in the `write_summary` function.

**Solution**: Use `--log` mode to see the actual output being generated.

### Version Command Returns "unknown"

This happens when the `VERSION` file is not found in the repository root.

**Solution**: Ensure the `VERSION` file exists at `../../VERSION` relative to the script location.

## Related

- [GitHub Actions - Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_run)
- [GitHub Actions - Job summaries](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#adding-a-job-summary)
- [GitHub Actions - Contexts](https://docs.github.com/en/actions/learn-github-actions/contexts)