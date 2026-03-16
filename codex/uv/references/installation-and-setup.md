# UV Installation and Setup Reference

## Overview

Use this reference to bootstrap uv itself, create new uv-managed projects, and handle compatibility-mode environments without mixing the two models.

## Install UV

### macOS / Linux

Standalone installer:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Homebrew:

```bash
brew install uv
```

### Windows

PowerShell installer:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Winget:

```powershell
winget install --id=astral-sh.uv -e
```

## Verify Installation

```bash
uv --version
uvx --version
```

If tools installed by uv are not available in new shells, run:

```bash
uv tool update-shell
uv python update-shell
```

## New Project Setup

Prefer the project workflow for new repositories:

```bash
uv init my-project
cd my-project
uv add httpx pytest ruff
uv sync
uv run pytest
uv run ruff check .
```

Typical project files:

```text
my-project/
├── pyproject.toml
├── uv.lock
├── .python-version
└── src/
```

## Existing UV Project

When the repository already has `pyproject.toml`, start with:

```bash
uv sync
uv run python -m your_package
```

If the project pins a Python version, keep that pin and avoid changing it implicitly.

## Compatibility Mode: Requirements-Based Environment

Use this path only when preserving pip-style environments.

### Create the Environment

```bash
uv venv
```

### Activate the Environment

Windows Git Bash:

```bash
. .venv/Scripts/activate
```

Windows CMD:

```cmd
.venv\Scripts\activate.bat
```

Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Linux / macOS:

```bash
source .venv/bin/activate
```

### Install Dependencies

```bash
uv pip install -r requirements.txt
uv pip install -e .
```

Use `uv pip` only after choosing this compatibility path, not as the default for a normal uv project.

## Existing Project Migration

### From `requirements.txt`

Keep the current packaging model, then migrate deliberately:

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

If migrating into a uv project:

```bash
uv init
uv add -r requirements.txt
uv sync
```

Review the generated dependency constraints before committing them.

### From Poetry / Pipenv

Target the uv project model:

```bash
uv init
uv add <dependencies...>
uv sync
```

Import dependencies explicitly instead of trying to preserve every tool-specific behavior automatically.

## Shell Integration

Use these commands when PATH or shims are missing:

```bash
uv tool update-shell
uv python update-shell
command -v uv
command -v uvx
```

If an IDE still cannot resolve the executable, use the absolute path in the IDE config.

## Recommended Setup Rules

- Prefer `uv init`, `uv add`, `uv sync`, `uv run` for new work.
- Prefer `uv venv` over `python -m venv` when uv owns the environment.
- Use `uv pip` only in compatibility-mode environments.
- Keep reproducible automation pinned to explicit versions.
- Repair shell integration before assuming uv is "missing".
