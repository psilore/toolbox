# Job Conclusion

A GitHub Actions utility script that checks workflow run conclusions and reports deployment results.

## Description

This script monitors the conclusion status of a GitHub Actions workflow run and provides formatted reporting. It's designed to be used in GitHub Actions workflows, particularly for deployment pipelines where you need to track and report on the success or failure of dependent workflows.

## Features

- ✅ Checks workflow run conclusion status
- 📊 Generates formatted GitHub Step Summary on failure
- 🔗 Provides direct links to failed workflow runs
- 🎯 Designed for deployment monitoring workflows

## Usage

### In GitHub Actions Workflow

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

### Using GitHub Context

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

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `GITHUB_EVENT_WORKFLOW_RUN_CONCLUSION` | The conclusion of the workflow run (`success`, `failure`, `cancelled`, etc.) | Yes | - |
| `GITHUB_EVENT_REPOSITORY_NAME` | Repository name | No | - |
| `GITHUB_EVENT_WORKFLOW_RUN_HTML_URL` | URL to the workflow run | No | - |
| `GITHUB_EVENT_WORKFLOW_RUN_RUN_NUMBER` | Workflow run number | No | - |
| `GITHUB_EVENT_WORKFLOW_RUN_NAME` | Workflow name from the workflow run event | No | - |
| `GITHUB_STEP_SUMMARY` | Path to GitHub step summary file | No | `/dev/null` |
| `DEPLOYMENT_ENVIRONMENT` | Deployment environment name (e.g., `prod`, `staging`, `dev`) | No | `prod` |
| `WORKFLOW_NAME` | Workflow display name for the summary | No | Falls back to `GITHUB_EVENT_WORKFLOW_RUN_NAME` or `deploy.yml` |

## Output

### Success Case

When the workflow conclusion is `success`:

- Prints: `Workflow succeeded`
- Exits with code `0`

### Failure Case

When the workflow conclusion is anything other than `success`:

- Prints: `Workflow failed`
- Generates a formatted step summary in the GitHub Actions UI
- Exits with code `1`

### Step Summary Format

On failure, the script creates a formatted table in the GitHub Step Summary:

```markdown
### 🚫 Deployment Failed!

**See job:**
| Name | Workflow | Run ID | Environment |
| --- | --- | --- | --- |
| repo-name | [Deploy to Production](https://github.com/...) | 123 | production |
```

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

## Exit Codes

- `0` - Workflow concluded successfully
- `1` - Workflow failed or had a non-success conclusion

## Example Scenarios

### Monitoring Deployment Workflows

Use this script to monitor deployment workflows and get notified when deployments fail:

```yaml
on:
  workflow_run:
    workflows: ["Deploy to Production"]
    types: [completed]
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
- GitHub Actions environment (uses GitHub-specific environment variables)

## Notes

- **Environment must be set manually** via `DEPLOYMENT_ENVIRONMENT` (defaults to `prod`)
- The workflow name is auto-detected from `${{ github.event.workflow_run.name }}` (defaults to `deploy.yml`)
- The script is specifically designed for the `workflow_run` trigger

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

## Related

- [GitHub Actions - Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_run)
- [GitHub Actions - Job summaries](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#adding-a-job-summary)
