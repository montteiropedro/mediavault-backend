# Repository Guidance

## Project conventions

- Keep application code, tests, comments, and project documentation in English.
- Follow the existing patterns in the surrounding code and the repository's RuboCop configuration.
- Add or update specs when changing application behavior.

## Validation

- Run the relevant RSpec specs inside the `backend` Docker Compose service:
  `docker compose exec backend bundle exec rspec <spec path>`
- When practical, run the full suite inside the same service:
  `docker compose exec backend bundle exec rspec`
- Report which commands were run and their results.

## Pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages and pull request titles. Use the format `type(scope): description` (scope is optional), with a lowercase type such as `feat`, `fix`, `docs`, `refactor`, `test`, or `chore`.
- Base every pull request description on `.github/pull_request_template.md`.
- Write every pull request title and description in English.
- Preserve the template's sections when preparing a pull request description.
