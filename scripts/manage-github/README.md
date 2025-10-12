# Manage team and repositores

A script to fetch GitHub repository names or team members using the GitHub CLI (`gh`).

## Features

- List repositories for a user, organization, or team
- List members of an organization or team
- Colorful, informative output (success, error, warning, info)
- Handles both comma and space separated arguments
- Helpful usage and error messages

## Requirements

- Bash
- [GitHub CLI (`gh`)](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)

## Usage

```sh
bash manage-github.sh [OPTIONS]
```

### Options

- `-h`, `--help`                  Show help message
- `-m`, `--members OWNER[,TEAM]`  Get members of the organization or team
- `-r`, `--repos OWNER[,TEAM]`    Get repositories for the owner or team

### Examples

- List repos for user/organization `acme`:

  ```sh
  bash manage-github.sh -r acme
  ```

- List repos in organization `acme` for team `dreamteam`:

  ```sh
  bash manage-github.sh -r acme,dreamteam
  ```

- List members of organization `acme`:

  ```sh
  bash manage-github.sh -m acme
  ```

- List members in organization `acme` for team `dreamteam`:

  ```sh
  bash manage-github.sh -m acme,dreamteam
  ```

## Notes

- You must be authenticated with the `gh` CLI and have appropriate permissions.
- The script uses colorized output for better readability.
- If an error occurs (e.g., API or jq failure), a helpful message is shown.

## License

[MIT](../../LICENSE)
