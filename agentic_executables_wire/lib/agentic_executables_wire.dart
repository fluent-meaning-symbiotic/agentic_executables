/// Agentic Executables wire contracts.
///
/// Pure Dart, zero-dependency data contracts shared between AE and agent
/// hosts (harness, CLI, MCP). AE owns the semantics; hosts consume the
/// shapes without embedding AE.
///
/// Two contracts live here:
/// - `verify_wire.dart` — tier-classified `VerifyEntry` gaps emitted by
///   `ae artifact verify`, plus the compact tier-ordered beat renderer.
/// - `meaning_tree_export.dart` — canonical-pack → meaning-tree export
///   (nodes/edges/props) for ECS-world hosts that project meaning per
///   decision instead of loading whole trees.
library;

export 'src/meaning_tree_export.dart';
export 'src/verify_wire.dart';
