# UV MCP Server Integration Reference

## Overview

Use this reference for MCP server execution with uv.

The current guidance is:

- Published package server: `uvx ...` or `uv tool run ...`
- Local project server: `uv run --directory ... python ...`
- Shared config: pin versions or omit them intentionally for ad-hoc local use
- Checked-in config: do not use floating latest specifiers

## Core Rule: Separate Published Packages From Local Code

### Published Package

Use `uvx` when the MCP server is published as a Python package:

```json
{
  "mcpServers": {
    "sqlite": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "/path/to/database.db"]
    }
  }
}
```

This is equivalent to using `uv tool run`.

### Local Project Code

Use `uv run` when the server lives inside a local repository:

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

Prefer this over `uvx --from ... script.py` for day-to-day local development.

## Versioning Guidance

### Good Defaults

- local ad-hoc use: unversioned package name is acceptable
- checked-in config: pin an exact version
- reproducible automation: pin an exact version

Examples:

```json
{
  "mcpServers": {
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git@1.0.0", "--repository", "/path/to/repo"]
    }
  }
}
```

### Avoid

- a floating latest specifier in committed config
- floating versions in CI examples
- editor settings that silently drift over time

## VS Code Example

`.vscode/mcp.json`

```json
{
  "mcpServers": {
    "fetch": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "local-server": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "${workspaceFolder}",
        "python",
        "src/server.py"
      ]
    }
  }
}
```

## Cursor / Continue Style Example

```json
{
  "experimental": {
    "modelContextProtocolServers": [
      {
        "transport": {
          "type": "stdio",
          "command": "uvx",
          "args": ["mcp-server-sqlite", "--db-path", "/Users/NAME/test.db"]
        }
      }
    ]
  }
}
```

## Troubleshooting

### "`spawn uvx ENOENT`"

Check shell integration and binary discovery first:

```bash
command -v uv
command -v uvx
uv tool update-shell
```

If the editor still cannot resolve `uvx`, use the absolute executable path.

### Local Project Cannot Find Dependencies

Use `uv run` from the project directory or pass `--directory` explicitly:

```bash
uv run --directory /absolute/path/to/project python src/server.py
```

### Need To Test The Packaged Entry Point

If the goal is specifically to test the installable CLI behavior of a packaged server, use `uvx` or `uv tool run`. If the goal is to execute local source code during development, use `uv run`.

## Practical Rules

- Published package server: `uvx`
- Local repository code: `uv run`
- Shared config: pin versions
- Troubleshooting: repair PATH before inventing fallbacks
