# UV Skill for Codex

This skill is the repository's current `uv` playbook, updated to **uv 0.10.10**.

It focuses on the current Astral-recommended command surface:

- Project workflow: `uv init`, `uv add`, `uv sync`, `uv run`
- Tool workflow: `uv tool install`, `uv tool run`, `uvx`
- Python runtimes: `uv python install`, `pin`, `find`, `upgrade`, `update-shell`
- Scripts: `uv init --script`, `uv add --script`, `uv run`
- MCP servers: `uvx` / `uv tool run` for published packages, `uv run` for local code

## What Changed In This Update

The previous version of this skill was organized around **uv 0.9.x** assumptions. This update moves the skill to a current baseline and fixes the main sources of drift:

- Stops treating an old `0.9.x` release as the latest stable release
- Makes the project workflow the default recommendation again
- Explains that `uvx` is the alias of `uv tool run`
- Uses `uv run` as the default for local scripts and local MCP development
- Adds current Python/runtime shell management commands
- Removes floating latest specifiers from shared examples and reproducibility guidance

## Quick Start

### Check Installed Version

```bash
uv --version
```

### Create A Project

```bash
uv init my-app
cd my-app
uv add httpx pytest ruff
uv sync
uv run pytest
```

### Install A Daily Tool

```bash
uv tool install ruff
uv tool update-shell
ruff check .
```

### Run A Tool Once

```bash
uv tool run ruff@0.6.9 check .
# alias:
uvx ruff@0.6.9 check .
```

### Run A Local Script

```bash
uv init --script cleanup.py --python 3.12
uv add --script cleanup.py rich
uv run cleanup.py
```

### Work In A Requirements-Based Environment

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

## Installation

Sync this repository's skills into the local Codex skill directory:

```bash
bash scripts/sync_skills.sh --dry-run
bash scripts/sync_skills.sh
```

Or copy the skill manually:

```bash
cp -r codex/uv ~/.codex/skills/uv
```

## Skill Structure

```text
codex/uv/
├── SKILL.md
├── README.md
├── VERSION
├── LICENSE
├── references/
│   ├── recent-changes.md
│   ├── installation-and-setup.md
│   ├── tool-management.md
│   ├── python-environment.md
│   ├── inline-script-metadata.md
│   └── mcp-integration.md
├── examples/
│   ├── common-patterns.md
│   ├── virtual-environments.md
│   ├── inline-scripts.md
│   ├── development-workflows.md
│   ├── mcp-servers.md
│   ├── ci-cd.md
│   ├── migrations.md
│   ├── anti-patterns.md
│   └── complete-workflow.md
└── docs/
    ├── guides/
    │   └── testing-the-uv-skill.md
    └── tasks/
        └── release/
            └── how-to-release.md
```

## Official Sources

Use official sources whenever a version-sensitive question comes up:

- Documentation: `https://docs.astral.sh/uv/`
- Installation: `https://docs.astral.sh/uv/getting-started/installation/`
- Tools guide: `https://docs.astral.sh/uv/guides/tools/`
- Scripts guide: `https://docs.astral.sh/uv/guides/scripts/`
- Python guide: `https://docs.astral.sh/uv/guides/install-python/`
- Releases: `https://github.com/astral-sh/uv/releases`

## Version Policy

- Current stable baseline for this skill: **uv 0.10.10**
- Verify with `uv --version` before giving version-specific advice
- Avoid hardcoding a floating "latest" in checked-in examples
- Pin versions when writing CI, IDE, or shared automation configs

## Validation

Validate the skill locally with:

```bash
python3 codex/skill-creator/scripts/quick_validate.py codex/uv
bash scripts/sync_skills.sh --dry-run
```
