/// Agentic Executables wire contracts.
///
/// Pure Dart, zero-dependency data contracts shared between AE and agent
/// hosts (harness, CLI, MCP). AE owns the semantics; hosts consume the
/// shapes without embedding AE.
///
/// Three contracts live here:
/// - `verify_wire.dart` — tier-classified `VerifyEntry` gaps emitted by
///   `ae artifact verify`, plus the compact tier-ordered beat renderer.
/// - `meaning_tree_export.dart` — canonical-pack → meaning-tree export
///   (nodes/edges/props) for ECS-world hosts that project meaning per
///   decision instead of loading whole trees; also carries the
///   `ae.knowledge_pack.v1` construct/deconstruct seam and the generic
///   canonical JSON form.
/// - `hub_manifest_wire.dart` — `ae.hub_manifest.v1`: pack id → canonical
///   file hash + version; the local-hub distribution seam (remote hub is
///   named, not built).
/// - `problem_wire.dart` — canonical diagnostic rows (AE-ETL over raw
///   analyzer/linter output) + project-guided repair-pack executables
///   (ADR 0021): the model never chooses the executable; the source
///   analyzer re-run is the oracle.
/// - `edit_executable_wire.dart` — parameterized edit executables (ADR
///   0023 §3): pack-declared, model slots, host span materialization.
library;

export 'src/hub_manifest_wire.dart';
export 'src/meaning_tree_export.dart';
export 'src/problem_wire.dart';
export 'src/edit_executable_wire.dart';
export 'src/verify_wire.dart';
