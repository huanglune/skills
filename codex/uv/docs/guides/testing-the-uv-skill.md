# Testing the UV Skill

## Purpose

Use this guide to validate that the `uv` skill answers with the current baseline:

- stable baseline: `uv 0.10.10`
- project-first workflow
- `uvx` explained as `uv tool run`
- `uv run` preferred for local project code
- no floating latest specifier in reproducible examples

## Preconditions

Before testing, confirm:

```bash
uv --version
python3 codex/skill-creator/scripts/quick_validate.py codex/uv
```

## Test Cases

### 1. Version Awareness

Prompt:

```text
What UV version should I target right now?
```

Expected answer:

- mentions `uv 0.10.10` as the current stable baseline for this skill
- tells the user to verify with `uv --version`
- points version-sensitive questions at official releases/docs

### 2. New Project Workflow

Prompt:

```text
How do I start a new Python project with UV?
```

Expected answer:

- uses `uv init`
- uses `uv add`
- uses `uv sync`
- uses `uv run`
- does not default to `python -m venv` + `uv pip`

### 3. Existing UV Project

Prompt:

```text
This repo already has pyproject.toml and uv.lock. What should I run first?
```

Expected answer:

- starts with `uv sync`
- uses `uv run ...` for follow-up commands

### 4. Tool Install vs One-Off Run

Prompt:

```text
Should I use uv tool install or uvx for Ruff?
```

Expected answer:

- recommends `uv tool install` for daily use
- explains `uvx` is the alias of `uv tool run`
- uses one-off execution for temporary usage/version comparison

### 5. Local Script Execution

Prompt:

```text
How should I run scripts/generate_docs.py in my uv project?
```

Expected answer:

- prefers `uv run python scripts/generate_docs.py`
- does not recommend `uvx --from . scripts/generate_docs.py` as the default

### 6. Inline Script Metadata

Prompt:

```text
How do I create a single-file script with dependencies in UV?
```

Expected answer:

- mentions PEP 723
- uses `uv init --script`
- uses `uv add --script`
- runs with `uv run script.py`

### 7. Python Runtime Management

Prompt:

```text
How do I install and pin Python 3.12 with UV?
```

Expected answer:

- uses `uv python install 3.12`
- uses `uv python pin 3.12`
- may mention `uv python find`, `uv python dir`, `uv python update-shell`
- does not rely on a floating default minor version

### 8. MCP Published Package

Prompt:

```text
How do I configure mcp-server-sqlite with uv in VS Code?
```

Expected answer:

- uses `uvx` or `uv tool run`
- provides a `stdio` config example
- does not use a floating latest specifier

### 9. MCP Local Development

Prompt:

```text
How do I run my local MCP server from /abs/project/src/server.py?
```

Expected answer:

- prefers `uv run --directory /abs/project python src/server.py`
- explains why local code should use the project environment

### 10. Requirements Compatibility

Prompt:

```text
My repo still uses requirements.txt. What should I do with UV?
```

Expected answer:

- uses `uv venv`
- activates the environment
- uses `uv pip install -r requirements.txt`
- frames this as compatibility mode rather than the default for new projects

## Regression Checks

Run these regression checks after edits:

```bash
! rg -n "0\\.9\\.7|0\\.9\\.6" codex/uv
```

## Final Validation

```bash
python3 codex/skill-creator/scripts/quick_validate.py codex/uv
bash scripts/sync_skills.sh --dry-run
```
