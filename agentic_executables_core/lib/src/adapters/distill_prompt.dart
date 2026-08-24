import 'dart:convert';

import '../models/distillation_task.dart';

/// Shared prompt header for AE distillation tasks. AE never calls a model:
/// this text is EMITTED as delegation instructions to the host agent
/// (Claude Code, pi, Codex CLI, Cursor…), which performs the work and
/// returns an `ae.canonical.draft.v1` JSON for AE to validate and merge.
const String distillPromptHeader = '''
You are running an AE distillation task. Return ONLY a JSON object that matches schema_out (`ae.canonical.draft.v1`). Do not wrap in prose; if you must, place the JSON in a single ```json fenced code block. No commentary outside the JSON.

ID STABILITY RULES (mandatory):
1. Every feature row you emit MUST have an `id` that already appears in the input task's `matrix_seed_rows`. You are enriching existing rows, not inventing new ones.
2. If you encounter a cross-cutting invariant that does not correspond to any seeded id (e.g. "all commands write a JSON envelope"), DO NOT create a feature row for it. Instead, append it to a top-level `proposed_concepts` array on your response, with shape:
   `{ "name": "<short-kebab-name>", "spec": "...", "invariant": "...", "rationale": "why this is cross-cutting, not a symbol" }`
3. If a seeded row is missing in the input but you believe a new symbol exists in the source artifact, DO NOT invent its id. Surface it as `proposed_concepts` with rationale "missing-from-scaffold; rerun ae canonical scaffold --update".

Schema reminder: the response object has top-level keys `schema`, `concept_id`, `concept_version`, `index_md`, `matrix`, optional `patterns_md`, optional `proposed_concepts`.

Response shape (return EXACTLY this structure, schema strings are literal):

```json
{
  "schema": "ae.canonical.draft.v1",
  "concept_id": "<from input.concept_id, string>",
  "concept_version": 1,
  "index_md": "<your enriched index markdown>",
  "matrix": {
    "schema": "ae.canonical_matrix.v1",
    "concept": "<from input.concept_id, string>",
    "version": 1,
    "column_schema": [{"id": "spec", "type": "text"}, {"id": "invariant", "type": "text"}],
    "features": [
      {"id": "<id from matrix_seed_rows>", "spec": "...", "invariant": "..."}
    ]
  },
  "proposed_concepts": [
    {"name": "<kebab-name>", "spec": "...", "invariant": "...", "rationale": "..."}
  ]
}
```

The `schema`, `concept_id`, `concept_version`, `index_md`, and `matrix` keys are REQUIRED on every response — the `matrix` key must always be present even if its `features` array is empty (do NOT omit `matrix` entirely). The `column_schema` and `features` arrays may be empty (`[]`). The `proposed_concepts` key is optional and may be omitted entirely when there are no proposals.
''';

/// Full delegation instructions: prompt header + the task JSON block.
/// AE emits this to the host agent; AE itself never calls a model.
String buildDistillInstructions(final DistillationTask task) {
  final taskJson = const JsonEncoder.withIndent('  ').convert(task.toJson());
  return '$distillPromptHeader\n```json\n$taskJson\n```\n';
}
