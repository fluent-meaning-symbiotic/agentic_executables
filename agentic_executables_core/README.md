# agentic_executables_core

Shared typed business logic for Agentic Executables v2.

## Why Core Exists

`agentic_executables_core` keeps AE domain behavior independent from transport layers.

This means:

- CLI, MCP, and future adapters share one source of truth.
- behavior is deterministic and testable.
- you can add new frontends without rewriting AE rules.

## Audience

### For Humans

Use core when you want to:

- embed AE workflows in your own Dart app/tool.
- implement custom adapters (HTTP service, IDE plugin, etc.).
- enforce typed contracts instead of ad-hoc JSON parsing.

### For Agents

Use core abstractions to:

- discover valid contexts/actions.
- generate AE files through pluggable engines.
- run verification and evaluation consistently.

## What Is Included

- Typed enums and DTOs (`AeContext`, `AeAction`, `AeResult<T>`, input/output models).
- Service interfaces and defaults:
  - instructions
  - definition
  - validation (verify + evaluate)
  - registry
  - generation
- Ports/adapters:
  - `DocumentStore`
  - `RegistryClient`
  - `GenerationEngine`
  - `InferenceClient`
  - `SkillTemplateProvider`
  - file-backed document store
  - GitHub raw registry client
  - deterministic template generation engine
  - `InferenceGenerationEngine` (provider-agnostic inference bridge)

## Generation Contract

Every generation engine must output exactly:

- `ae_install.md`
- `ae_uninstall.md`
- `ae_update.md`
- `ae_use.md`

`DefaultAeGenerationService` validates this contract and handles `auto` fallback behavior (`codex` -> `template`).

## Quick Integration Example

```dart
final instructions = DefaultAeInstructionService(
  FileDocumentStore('/path/to/prompts_framework'),
);

final result = await instructions.getInstructions(
  const GetInstructionsInput(
    context: AeContext.library,
    action: AeAction.bootstrap,
  ),
);
```

## Provider-Agnostic Inference

You can plug any inference backend (not only Codex):

```dart
final engine = InferenceGenerationEngine(client: MyInferenceClient());
```

Reference guide: `../docs/guides/inference_provider_guide.md`

## Typical Workflows

1. Build adapter -> call core services -> return your transport envelope.
2. Create custom `InferenceClient` -> inject into generation service.
3. Reuse core verify/evaluate scoring in CI quality gates.

## Testing

```bash
dart test
```

Covered behaviors include:

- context/action mapping and validation.
- registry id/path resolution and submit/get behavior.
- verify/evaluate scoring parity.
- generation file contract checks.
- engine selection and fallback logic.
