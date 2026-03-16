# UV Current Baseline and Change Notes

## Current Stable Baseline

- **Latest stable baseline for this skill:** `uv 0.10.10`
- **Version check command:** `uv --version`
- **Primary release source:** `https://github.com/astral-sh/uv/releases`
- **Primary documentation source:** `https://docs.astral.sh/uv/`

This file intentionally focuses on the current operating baseline instead of trying to duplicate Astral's full patch-by-patch changelog.

## What This Skill Changed

The previous revision of this skill was anchored on an older `uv 0.9.x` baseline. That caused two practical problems:

1. It hardcoded an outdated "latest version".
2. It over-centered older compatibility workflows instead of the current first-class uv workflows.

This update corrects that by reorganizing guidance around the current command surface.

## Current Guidance Summary

### 1. Default To The Project Workflow

For normal repositories, prefer:

```bash
uv init
uv add
uv sync
uv run
```

Use `uv pip` when preserving a pip-style environment or a `requirements.txt` workflow, not as the first recommendation for new uv projects.

### 2. Treat `uvx` As `uv tool run`

`uvx` is the alias for `uv tool run`.

That means:

- `uvx ruff check .` and `uv tool run ruff check .` are the same execution model
- `uv tool install` remains the persistent-install path
- `uv run` remains the project-command path

### 3. Prefer `uv run` For Local Code

Use `uv run` for:

- project commands
- local scripts
- local MCP server development
- script execution with inline metadata

Examples:

```bash
uv run python scripts/build_docs.py
uv run cleanup.py
uv run --directory /absolute/path/to/project python src/server.py
```

### 4. Use Current Python Runtime Commands

Current Python management guidance should include:

```bash
uv python install 3.12
uv python pin 3.12
uv python find 3.12
uv python dir
uv python upgrade
uv python update-shell
```

Do not assume the default Python minor version is stable across uv releases. If the exact version matters, specify it directly.

### 5. Avoid Floating Versions In Shared Config

Do not recommend floating latest specifiers in:

- IDE MCP settings
- checked-in JSON configs
- CI pipelines
- automation examples

Prefer one of these instead:

- omit the version for casual ad-hoc local use
- pin an exact version for reproducibility

## Migration Notes From The Older Skill

### Old Default: Manual Venv + `uv pip`

Still valid for compatibility:

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

But for a standard uv project, prefer:

```bash
uv sync
uv run pytest
```

### Old Default: `uvx --from ... script.py` For Local Scripts

Replace that pattern with `uv run` when executing local project code:

```bash
uv run --directory /path/to/project python script.py
```

Reserve `uvx` / `uv tool run` for packaged CLI entry points or published packages.

### Old Default: Repeated "Latest Version" Notes

Do not spread version-specific claims across many files without an update strategy.

Keep version-sensitive guidance concentrated in:

- `SKILL.md`
- `README.md`
- this file

and verify against official releases before editing.

## Official References To Check Before Answering

- Installation: `https://docs.astral.sh/uv/getting-started/installation/`
- Projects: `https://docs.astral.sh/uv/guides/projects/`
- Tools: `https://docs.astral.sh/uv/guides/tools/`
- Scripts: `https://docs.astral.sh/uv/guides/scripts/`
- Python versions: `https://docs.astral.sh/uv/guides/install-python/`
- Releases: `https://github.com/astral-sh/uv/releases`

## Short Verification Checklist

Before finalizing UV guidance, confirm:

- `uv --version` output on the target machine
- whether the repo is a uv project or a pip-style environment
- whether the task is about a project command, a CLI tool, a script, or a Python runtime
- whether reproducibility requires pinned versions
