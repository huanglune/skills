# Python Environment Management Reference

## Overview

Use `uv python` for interpreter management and `uv run` for interpreter selection at execution time.

Separate these concerns:

- interpreter lifecycle: `uv python ...`
- project execution: `uv run ...`
- compatibility-mode package installs: `uv pip ...`

## Core Commands

### Install Interpreters

```bash
uv python install
uv python install 3.12
uv python install 3.12 3.13
```

If the exact version matters, specify it directly instead of relying on uv's current default.

### Inspect Available Interpreters

```bash
uv python list
uv python list --installed
uv python find 3.12
uv python dir
```

### Pin A Project Version

```bash
uv python pin 3.12
cat .python-version
```

Use a pin whenever the repository or deployment target expects a specific Python version.

### Upgrade Managed Interpreters

```bash
uv python upgrade
uv python upgrade 3.12
```

### Update Shell Integration

```bash
uv python update-shell
```

Run this when newly installed Python executables are not visible in fresh shells or IDE terminals.

## Choosing A Python At Runtime

Use `uv run --python ...` when the command should run with a specific interpreter:

```bash
uv run --python 3.12 pytest
uv run --python 3.13 python -m your_package
uv run --python /absolute/path/to/python python script.py
```

This is execution-time selection. It does not replace the project's pinned version strategy.

## Project Recommendations

### For A UV Project

Prefer:

```bash
uv python pin 3.12
uv sync
uv run pytest
```

### For A Legacy Environment

Prefer:

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

Use `uv python` only to manage the interpreter inventory, not to replace the compatibility-mode environment model.

## Environment Variables

Use `UV_PYTHON_INSTALL_DIR` only when a custom interpreter storage location is required:

```bash
export UV_PYTHON_INSTALL_DIR=/custom/path/to/uv-python
```

Keep this explicit because changing the install location affects discoverability and debugging.

## Recommended Rules

- Pin the Python version when reproducibility matters.
- Use `uv python find` and `uv python dir` for debugging.
- Use `uv python update-shell` before assuming PATH is broken.
- Use `uv run --python ...` for per-command interpreter overrides.
- Do not hardcode the current default Python minor version into persistent guidance.
