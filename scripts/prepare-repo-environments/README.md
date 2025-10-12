# Prepare a repository with environments

A Bash script to manage GitHub Environments in a repository using the GitHub CLI (`gh`).

## Features

- Create one or more environments in a GitHub repository
- Remove one or more environments
- List all existing environments
- Supports specifying the repository or using the current repo
- Colorful, informative output

## Requirements

- Bash
- [GitHub CLI (`gh`)](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)

## Usage

```sh
./prepare-repo-environments.sh [--list] [--remove] <environment-name>... [--repo <owner/repo>]
```

### Options

- `--list`                List all existing environments in the repository
- `--remove`              Remove the specified environments instead of creating them
- `<environment-name>`    One or more environment names to create or remove
- `--repo <owner/repo>`   Target repository in `owner/repo` format (optional, defaults to current repo)

### Examples

- List all environments in a repository:

  ```sh
  ./prepare-repo-environments.sh --list --repo psilore/toolbox
  ```

- Create environments:

  ```sh
  ./prepare-repo-environments.sh dev prod staging --repo psilore/toolbox
  ```

- Remove an environment:

  ```sh
  ./prepare-repo-environments.sh --remove dev --repo psilore/toolbox
  ```

- Create an environment in the current repository:

  ```sh
  ./prepare-repo-environments.sh test
  ```

## Notes

- You must be authenticated with the `gh` CLI and have appropriate permissions on the repository.
- If no environments are found when listing, the script will print a helpful message.
- The script uses colorized output for better readability.

## License

[MIT](../../LICENSE)
