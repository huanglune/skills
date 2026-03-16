---
name: uv
description: This skill should be used when the user asks about UV (Astral's Python package manager), modern uv project workflows (`uv init` / `uv add` / `uv sync` / `uv run`), the `uv tool` / `uvx` distinction, Python runtime management, inline script metadata, MCP server execution with uv, or migration from pip, pipx, poetry, or pyenv. Use when queries mention UV, UVX, Python package management, virtual environments, Python versions, CLI tools, or MCP servers.
---

# UV - Python Package Manager Skill

## Overview

Treat this skill as the current operational guide for **uv 0.10.10**.

Start every version-sensitive task with:

```bash
uv --version
```

Use the current official docs and releases as the source of truth:

- Docs: `https://docs.astral.sh/uv/`
- Releases: `https://github.com/astral-sh/uv/releases`

## Current Baseline

- Assume **uv 0.10.10** unless the user's machine reports another version.
- Prefer the **project workflow** for modern repos: `uv init`, `uv add`, `uv sync`, `uv run`.
- Treat **`uvx` as an alias of `uv tool run`**, not as a separate execution model.
- Use **`uv tool install`** for persistent CLI applications.
- Use **`uv run`** for local project commands and single-file scripts.
- Reserve **`uv pip`** for pip-compatible or `requirements.txt`-driven environments.
- Avoid floating latest specifiers in checked-in configs, CI, IDE settings, and reproducible automation.

## When To Use This Skill

Use this skill when the task involves:

- Creating or maintaining a uv-managed Python project
- Choosing between `uv run`, `uv tool install`, `uv tool run`, and `uv pip`
- Installing or pinning Python runtimes with `uv python ...`
- Running or packaging single-file scripts with inline metadata
- Configuring MCP servers through `uvx` / `uv tool run`
- Migrating from `pip`, `pipx`, `poetry`, `pyenv`, or ad-hoc virtualenv workflows

Skip this skill when the task is unrelated to Python tooling or package management.

## Default Decision Table

| Need | Prefer | Notes |
| --- | --- | --- |
| Create or work on a normal Python project | `uv init`, `uv add`, `uv sync`, `uv run` | Default path for `pyproject.toml` projects |
| Run a command inside a uv-managed project | `uv run ...` | Uses the project environment |
| Install a CLI tool for repeated daily use | `uv tool install ...` | Persistent isolated installation |
| Run a CLI tool once or test a version | `uv tool run ...` or `uvx ...` | `uvx` is just the alias |
| Run a local script | `uv run script.py` or `uv run python script.py` | Prefer project/script flow over `uvx` |
| Manage Python runtimes | `uv python ...` | Install, pin, find, upgrade, update shell |
| Work in a legacy `requirements.txt` environment | `uv venv` + `uv pip ...` | Compatibility mode, not the default |

## Recommended Workflows

### 1. Modern Project Workflow

Prefer uv's project commands when the repository uses or can use `pyproject.toml`.

```bash
# Create a new project
uv init example-app
cd example-app

# Add dependencies
uv add fastapi ruff pytest

# Sync the environment from project metadata
uv sync

# Run commands inside the project environment
uv run python -m example_app
uv run pytest
uv run ruff check .
```

Use `uv sync` as the default entry point when the repo already contains `pyproject.toml` and optionally `uv.lock`.

### 2. Tool Management

Install tools permanently when they are used frequently:

```bash
uv tool install ruff
uv tool install basedpyright
uv tool install pre-commit
uv tool update-shell
```

Run tools temporarily when testing, comparing versions, or avoiding persistent installs:

```bash
uv tool run ruff check .
uvx ruff@0.6.9 format .
```

Prefer `uv tool install` for daily tools and `uv tool run` / `uvx` for one-off execution.

### 3. Scripts and One-Off Commands

Prefer `uv run` for local scripts:

```bash
uv run script.py
uv run python scripts/generate_report.py
uv run --with httpx --with rich python scripts/check_api.py
```

Use PEP 723 inline metadata for single-file scripts, then maintain them with:

```bash
uv init --script cleanup.py --python 3.12
uv add --script cleanup.py rich httpx
uv run cleanup.py
```

### 4. Python Runtime Management

Use `uv python` for interpreter lifecycle management:

```bash
uv python install 3.12 3.13
uv python list
uv python pin 3.12
uv python find 3.12
uv python dir
uv python upgrade
uv python update-shell
```

When the exact Python version matters, specify it explicitly. Do not rely on whatever the current default minor version happens to be.

### 5. Compatibility / Pip Interface

Use `uv pip` only when preserving an existing pip-style environment:

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
uv pip install -e .
```

This path is valid for migrations and legacy repos, but it is not the preferred default for new uv projects.

## MCP Guidance

### Published MCP Servers

For published packages, `uvx` remains a practical choice because many editor examples already use it:

```json
{
  "mcpServers": {
    "sqlite": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "/path/to/db.sqlite"]
    }
  }
}
```

Interpret that as `uv tool run`, not as a separate product surface.

### Local MCP Server Development

Prefer `uv run` for local server code:

```json
{
  "mcpServers": {
    "local-server": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "/absolute/path/to/project",
        "python",
        "src/server.py"
      ]
    }
  }
}
```

Prefer this over `uvx --from ... script.py` when the goal is to execute local project code with its project environment.

### Reproducibility Rules

- Pin external package versions in checked-in configs when reproducibility matters.
- Avoid floating latest specifiers in editor settings, CI, and shared automation.
- Use absolute paths when editors cannot resolve the workspace correctly.

## Shell and PATH Repair

When commands exist but editors cannot find them, repair shell integration first:

```bash
uv tool update-shell
uv python update-shell
command -v uv
command -v uvx
```

If an IDE still cannot resolve `uv` or `uvx`, use the absolute executable path in the config.

## Operating Rules For This Skill

- Verify the installed version before giving version-sensitive advice.
- Prefer project metadata over ad-hoc virtualenv commands when both are available.
- Prefer `uv run` for local project commands and scripts.
- Explain that `uvx` is the alias of `uv tool run` when the distinction matters.
- Treat `uv pip` as a compatibility layer, not the first recommendation.
- Pin versions in persistent configs; leave floating versions only for explicit ad-hoc testing.
- Surface failures directly. Do not invent fallback commands that hide environment problems.

## References To Load On Demand

- `references/recent-changes.md`
  Current baseline, official sources, and migration notes from the old `0.9.x` guidance.
- `references/installation-and-setup.md`
  Installation, new-project bootstrap, and compatibility-mode setup.
- `references/tool-management.md`
  Detailed comparison of `uv tool install`, `uv tool run`, and `uvx`.
- `references/python-environment.md`
  Python runtime installation, pinning, shell integration, and interpreter selection.
- `references/inline-script-metadata.md`
  PEP 723 script workflow, `uv init --script`, `uv add --script`, and `uv run`.
- `references/mcp-integration.md`
  Published vs local MCP execution patterns and editor configuration.

## Short Answer Templates

### New Project

```bash
uv init my-app
cd my-app
uv add requests
uv sync
uv run python -m my_app
```

### Daily Tool

```bash
uv tool install ruff
uv tool update-shell
ruff check .
```

### One-Off Tool

```bash
uvx ruff@0.6.9 check .
```

### Existing `requirements.txt`

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```
