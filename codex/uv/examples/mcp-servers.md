# MCP Server Examples

## Overview

Use these examples as current uv-oriented MCP patterns:

- published package server: `uvx`
- local project server: `uv run`
- checked-in config: no floating latest specifier

## Published MCP Servers

### Model Context Protocol Servers

```json
{
  "mcpServers": {
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/repo"]
    },
    "sqlite": {
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "/path/to/database.db"]
    },
    "filesystem": {
      "command": "uvx",
      "args": [
        "mcp-server-filesystem",
        "/allowed/path1",
        "/allowed/path2"
      ]
    },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    }
  }
}
```

### Published Packages That Should Be Pinned In Shared Config

```json
{
  "mcpServers": {
    "core": {
      "command": "uvx",
      "args": ["awslabs.core-mcp-server@1.0.0"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    },
    "lambda": {
      "command": "uvx",
      "args": ["awslabs.lambda-mcp-server@1.0.0"],
      "env": {
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

Replace the example version with the exact version that has actually been tested in your environment.

## Local MCP Server Development

### Basic Local Development

```json
{
  "mcpServers": {
    "local-server": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "d:/mcp/my.python/sqlplugins",
        "python",
        "mcp_server.py",
        "--env",
        "d:/mcp/my.python/sqlplugins/hr2.env"
      ]
    }
  }
}
```

### Development and Packaged Variants

```json
{
  "mcpServers": {
    "dev-server": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "${workspaceFolder}",
        "python",
        "src/server.py",
        "--debug"
      ]
    },
    "prod-server": {
      "command": "uvx",
      "args": ["my-mcp-server@1.0.0"]
    }
  }
}
```

## Related Documentation

- [MCP Integration Reference](../references/mcp-integration.md)
- [Inline Script Metadata](../references/inline-script-metadata.md)
- [Installation and Setup](../references/installation-and-setup.md)
