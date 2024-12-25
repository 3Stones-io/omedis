# Contributing to Omedis

Welcome to the Omedis project! Before starting, please check if your question is already answered in our [Wiki](https://github.com/wintermeyer/omedis/wiki) or [Discussions](https://github.com/wintermeyer/omedis/discussions). Feel free to start a new discussion if needed.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Working on Issues](#working-on-issues)
- [Pull Requests](#pull-requests)
- [Code Quality and Testing](#code-quality-and-testing)
- [Translations](#translations)
- [Documentation](#documentation)
- [Getting Help](#getting-help)

## Getting Started

1. **Setup Your Environment**:
   - Clone the repository: `git clone https://github.com/wintermeyer/omedis.git`
   - Follow the setup instructions in [README.md](README.md) carefully
   - Install all required dependencies and setup your database
   - Run `mix setup` to verify your environment

2. **First Time Contributors**:
   - Browse the [issues labeled "good first issue"](https://github.com/wintermeyer/omedis/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
   - Check our [Kanban board](https://github.com/users/wintermeyer/projects/1) for available tasks

## Development Workflow

- **Starting New Work**:
   ```bash
   git checkout main
   git pull
   git checkout -b 123-feature-name
   ```

- **Branch Naming Convention**:
   - Format: `<issue-number>-<brief-description>`
   - Example: `235-add-registration-via-invites`
   - Use hyphens for spaces
   - Keep it concise but descriptive

- **Updating Your Branch**:
   ```bash
   git checkout main
   git pull
   git checkout your-branch
   git merge main
   ```

   > [!WARNING]
   > We've had unnecessary merge conflicts in the past caused by bad habits.  
   > Make sure to always keep your branches in sync with `main` before merging.

## Working on Issues

1. **Before Starting**:
   - Move your issue to "In Progress" on the [Kanban board](https://github.com/users/wintermeyer/projects/1)
   - Break down large tasks into smaller PRs
   - Use `TODO`/`FIXME` comments for incomplete sections
   - Review existing implementations of similar features
   - Ask questions in the issue if requirements are unclear

2. **Resource Changes**:
   - Add new or update existing Ash resources
   - Run `mix ash_postgres.generate_migrations` to make database changes
   - Review generated migrations carefully
   - Commit resource snapshots
   - Update `priv/repo/seeds/demo_seeds.exs` if needed
   - Test migrations both up and down (rollback)

3. **Best Practices**:
   - Keep changes focused and minimal
   - Ask for help early if stuck
   - Check existing code for similar implementations
   - Document complex logic with comments
   - Consider edge cases in your tests

## Pull Requests

1. **Before Submitting**:
   - Run `make check_code` locally
   - Ensure all tests pass
   - Include translations for new text
   - Review your own changes first
   - Test the feature in development environment

2. **PR Guidelines**:
   - Link to issue in the PR description (e.g. "Fixes #123")
   - Keep changes focused on one feature/fix
   - Create separate issues and PRs for refactoring
   - Describe your changes clearly in the PR description
   - Add screenshots/screencasts for UI changes
   - List any breaking changes
   - Update documentation if needed
   - Request a review
   - Move the issue to "In Review" column on the Kanban board

## Code Quality and Testing

- Follow existing code style
- Add tests for new features
- Run `make check_code` before committing
- Ensure CI passes (check [ci.yml](.github/workflows/ci.yml))

## Translations

When adding new UI elements, make sure to add the corresponding translations.

1. **Adding New Strings**:
   ```bash
   mix gettext.extract --merge
   ```

2. **If Issues Occur**:
   ```bash
   rm -rf priv/gettext
   mkdir -p priv/gettext/{de,en,fr,it}/LC_MESSAGES
   mix gettext.extract
   mix gettext.merge priv/gettext
   ```

3. **Translation Process**:
   - Use [Cursor](https://www.cursor.com) with gpt-4o for new translations
   - Make sure to update all language files

## Documentation

- Update [Wiki](https://github.com/wintermeyer/omedis/wiki) for process changes
- Keep setup instructions in [README.md](README.md) up to date
- Update this file when processes change

## Getting Help

- Create new [Discussions](https://github.com/wintermeyer/omedis/discussions) and tag team members
- Post questions in https://elixirforum.com/c/ash-framework-forum/123
- After getting answer, improve [Wiki](https://github.com/wintermeyer/omedis/wiki) and Ash documentation https://hexdocs.pm/ash/readme.html

## Checklist

Before starting work:
- [ ] Issue has sufficient details
- [ ] Task is broken down if needed
- [ ] Issue is on Kanban board with status "In Progress"

For resource changes:
- [ ] Migrations are generated and reviewed
- [ ] Resource snapshots are committed
- [ ] Seeds are updated if needed

Before submitting PR:
- [ ] Code checks pass locally
- [ ] Tests are added and passing
- [ ] Translations are included
- [ ] Screenshots/recordings added for UI changes
- [ ] Documentation is updated
- [ ] Issue is linked
- [ ] Issue moved to "In Review"

Thank you for contributing to Omedis! Your efforts help make this project better for everyone.
