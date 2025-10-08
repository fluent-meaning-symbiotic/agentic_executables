AI_USE

We need to create mcp package for @prompts_framework/ based on @https://pub.dev/packages/dart_mcp

# How it should work:

This MCP server is a strategic thinking Tool for AI Agents to use, so the primary purpose is to provide guidances for the agents to use Agentic Executables (AE).

# Cases when it should be used:

1. When AI Agent needs to bootstrap / update / uninstall AE for the library.
2. When AI Agent needs to install / uninstall / update library as AE to specific project.

# Extremely important:

1. AE is framework to manage libraries, so it should be used to manage libraries.
2. AE is framework and language agnostic. Meaning: the developer could use this framework to manage libraries in any language.

- Therefore the AI Agent should be guided to use this framework in any language.
- Therefore this MCP should give answers to HOW to manage AE, not tools to install / uninstall / update libraries.
