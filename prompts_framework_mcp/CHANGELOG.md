# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Registry integration: `manage_ae_registry` tool with 3 operations
  - `submit_to_registry`: Generate PR instructions for library authors
  - `get_from_registry`: Fetch library AE files directly
  - `bootstrap_local_registry`: Set up monorepo registry structure
- `get_agentic_executable_definition` tool for AE framework overview
- Centralized `AEFrameworkConfig` with registry configuration
- `AEValidationConfig` for objective metrics
- GitHub raw file fetcher for registry access
- Registry resolver for path and URL building
- Library ID validation (`<language>_<library_name>` format)
- Structured evaluation with LOC scoring (favors conciseness)
- `ae_install.md` - AI agent installation guide

### Changed

- Updated all tool descriptions to include structured metrics
- Consolidated documentation from 3 files to 2 (README.md + ae_install.md)
- Removed QUICKSTART.md and GETTING_STARTED.md (content merged)
- Enhanced README.md with registry workflows and all 5 tools
- Updated tool count: 3 → 5 tools
- Improved architecture documentation with registry components

### Fixed

- Documentation now accurately reflects current feature set
- Consistent terminology across all documentation

## [0.1.0] - 2025-10-08

### Added

- Initial release of Prompts Framework MCP Server
- Three core MCP tools for AE framework guidance:
  - `get_ae_instructions`: Retrieve contextual AE documentation
  - `verify_ae_implementation`: Generate verification checklists
  - `evaluate_ae_compliance`: Evaluate compliance with scoring
- STDIO transport support for MCP communication
- Resource management for AE documentation files
- Docker support with multi-stage build
- Comprehensive test suite
- Example test script
- Full documentation and README

### Features

- Language and framework agnostic guidance
- Strategic HOW-TO instructions for AI agents
- Principle-based evaluation system
- Automatic validation of tool arguments
- JSON-formatted responses for easy parsing
- Compiled binary support for production deployment

[0.1.0]: https://github.com/fluent-meaning-symbiotic/agentic_executables/releases/tag/v0.1.0
