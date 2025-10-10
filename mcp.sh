#!/usr/bin/env bash
claude mcp add awslabs.aws-documentation-mcp-server -s user uvx awslabs.aws-documentation-mcp-server@latest
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project /workspace
