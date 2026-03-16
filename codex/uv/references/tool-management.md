# UV Tool Management Reference

## Overview

Use this reference to decide between:

- `uv tool install`
- `uv tool run`
- `uvx`
- `uv run`

The key distinction is whether the command is a persistent CLI tool, a one-off tool execution, or code that belongs to a project.

## Decision Table

| Scenario | Prefer | Why |
| --- | --- | --- |
| Install a daily CLI tool | `uv tool install ruff` | Persistent isolated install |
| Run a tool once | `uv tool run ruff check .` | No long-lived install required |
| Use the short alias | `uvx ruff check .` | Alias of `uv tool run` |
| Run code from the current project | `uv run ...` | Uses the project environment |
| Run a local Python script | `uv run python scripts/task.py` | Local code should stay in the project model |

## Persistent Tool Installation

Install tools that are used repeatedly:

```bash
uv tool install ruff
uv tool install basedpyright
uv tool install pre-commit
uv tool update-shell
```

Useful management commands:

```bash
uv tool list
uv tool show ruff
uv tool upgrade ruff
uv tool upgrade --all
uv tool uninstall ruff
```

Use this path for formatters, linters, release helpers, and CLI utilities that should feel globally available.

## One-Off Tool Execution

Run tools without permanently installing them:

```bash
uv tool run ruff check .
uv tool run ruff@0.6.9 format .

# alias
uvx ruff check .
uvx ruff@0.6.9 format .
```

Use this path for:

- temporary experiments
- version comparisons
- single-use commands
- editor or automation integrations that intentionally avoid a persistent install

## `uvx` vs `uv tool run`

They are the same execution model.

Prefer whichever form improves clarity in context:

- `uv tool run ...` when explaining the command family explicitly
- `uvx ...` when following community examples or editor docs

Do not explain them as different products.

## `uv run` Is Not A Tool Command

Use `uv run` when the command belongs to a project:

```bash
uv run pytest
uv run ruff check .
uv run python scripts/build_docs.py
```

This differs from `uv tool run`:

- `uv run` executes in the project environment
- `uv tool run` executes a tool package entry point

If the user is asking how to run local project code, recommend `uv run`, not `uvx`.

## Versioning Rules

### Safe Defaults

- Omit the version for ad-hoc local use
- Pin exact versions for shared automation and reproducibility
- Avoid floating latest specifiers in committed files

Examples:

```bash
# ad-hoc local use
uvx ruff check .

# pinned automation
uvx ruff@0.6.9 check .
```

### Shared Config Guidance

For CI, editor settings, and team scripts:

- prefer `uv tool install` plus explicit upgrade policy, or
- use `uv tool run` / `uvx` with an exact pinned version

Do not rely on a floating latest specifier.

## Common Recommendations

### Daily Development Tools

```bash
uv tool install ruff
uv tool install basedpyright
uv tool install pytest
uv tool update-shell
```

### Version Comparison

```bash
uvx ruff@0.6.8 check .
uvx ruff@0.6.9 check .
```

### Local Project Command

```bash
uv run pytest
uv run python scripts/sync_data.py
```

## Anti-Patterns

- Using `uvx` for daily commands that should simply be installed once
- Using `uv tool run` for local project scripts
- Treating `uvx` as something different from `uv tool run`
- Using a floating latest specifier in committed config
- Mixing "global Python package install" advice into tool guidance
