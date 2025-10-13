# Agentic Executables (AE) Registry - Demo

This folder contains **demo/example AE files** for reference and testing purposes only.

## 🔗 Official Registry

**The official AE registry is located at:**  
https://github.com/fluent-meaning-symbiotic/agentic_executables_registry

All production library AE files are maintained in the external registry under the `ae_use/` directory.

## Purpose of This Demo Folder

This local `ae_use_registry/` folder serves as:

- **Examples** - Reference implementations showing proper AE file structure
- **Testing** - Local test cases for MCP server development
- **Documentation** - Learning resources for library authors

## Using the Official Registry

The MCP server automatically fetches from the official registry. When you use commands like:

```
Operation: get_from_registry
Library ID: dart_xsoulspace_lints
Action: install
```

The MCP server fetches from:  
`https://github.com/fluent-meaning-symbiotic/agentic_executables_registry/tree/main/ae_use/dart_xsoulspace_lints/`

## Browsing Available Libraries

Visit the official registry to browse all available libraries:  
https://github.com/fluent-meaning-symbiotic/agentic_executables_registry/tree/main/ae_use

## Contributing

To contribute your library to the official registry, see:  
[CONTRIBUTING.md](./CONTRIBUTING.md)

---

**Note:** Do not submit PRs to add libraries in this demo folder. All submissions should go to the official registry repository.
