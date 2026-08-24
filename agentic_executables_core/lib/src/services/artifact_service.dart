import 'dart:io';

import '../models/artifact_matrix.dart';
import '../models/artifact_pack.dart';
import '../models/verify_report.dart';

/// Per-pack outcome of [ArtifactService.sync]. Spec §6.2.
class SyncOutcome {
  const SyncOutcome({required this.changed, required this.pruned});

  /// True if any source file's sha256 differed from the persisted meta.
  final bool changed;

  /// True when [ArtifactService.sync] was invoked with `prune: true` and
  /// the artifact's `meta.source.path` did not exist on disk, causing the
  /// pack to be removed from the hub.
  final bool pruned;
}

/// Result of [ArtifactService.markEvidence]: the feature's cell before and
/// after, so callers can show exactly what changed.
class MarkEvidenceResult {
  const MarkEvidenceResult({
    required this.pack,
    required this.featureId,
    required this.cell,
  });

  final String pack;
  final String featureId;
  final ArtifactCell cell;
}

abstract interface class ArtifactService {
  /// List all artifact pack names.
  Future<List<String>> list();

  /// Load an artifact pack by name.
  Future<ArtifactPack?> load(final String name);

  /// Ingest [sourceDir] using the appropriate heuristic extractor and persist
  /// the resulting artifact under [ArtifactKind.local]. Returns the pack name.
  Future<String> ingest(final Directory sourceDir);

  /// Re-scan the source files for [packName], updating file hashes in
  /// `meta.source.files`. Returns true if any file changed.
  ///
  /// Legacy signature retained so existing callers (and tests) keep
  /// working. New callers should prefer [syncOne] for the structured
  /// result that carries prune semantics from spec §6.2.
  Future<bool> sync(final String packName);

  /// Re-scan the source files for [packName] and return a [SyncOutcome].
  /// When [prune] is true and the artifact's `meta.source.path` no longer
  /// exists on disk, the artifact pack directory is removed from the hub
  /// and `pruned: true` is reported. Spec §6.2.
  Future<SyncOutcome> syncOne(
    final String packName, {
    final bool prune = false,
  });

  /// Add a canonical reference to [packName]'s `references_canonical` list.
  /// If [lockedVersion] is null, the reference is live.
  Future<void> link(
    final String packName,
    final String conceptId, {
    final int? lockedVersion,
  });

  /// Upgrade an existing canonical reference to a new locked version.
  /// Re-materializes matrix rows for the new feature set.
  Future<void> upgradeCanonical(
    final String packName,
    final String conceptId, {
    required final int toVersion,
  });

  /// Auto-add matrix rows for every canonical feature referenced by [packName]
  /// that doesn't already appear in the artifact matrix. Default impl status:
  /// missing. Existing rows are preserved (their cell values are not touched).
  Future<int> materialize(final String packName);

  /// Single-artifact tier-classified verify. Includes:
  ///   - Tier 1: invariant violations on referenced canonical features
  ///   - Tier 3: partial features
  ///   - Tier 4: unreferenced canonicals (present in hub but not in
  ///     [ArtifactMeta.referencesCanonical])
  /// Tier 2 (upstream blockers) is project-scoped — see [verifyProject].
  ///
  /// When [runTests] is true, every referenced-canonical row carrying an
  /// `evidence_command` is executed (not trusted): exit 0 confirms the
  /// evidence; a failing command becomes a Tier 1 entry — the pack is
  /// caught lying about its own evidence.
  Future<VerifyReport> verifyOne(
    final String packName, {
    final bool runTests = false,
  });

  /// Records test evidence for one feature row of an artifact. Sets the
  /// cell's test status, records provenance ([location], [testCommand]),
  /// and promotes `impl: missing` to [impl] (default `done`) so evidence
  /// never sits on a missing implementation.
  Future<MarkEvidenceResult> markEvidence(
    final String packName,
    final String featureId, {
    required final String testCommand,
    final String? location,
    final String? notes,
    final TestStatus tests = TestStatus.yes,
    final ImplStatus impl = ImplStatus.done,
  });

  /// Project-wide verify across all artifacts. Computes downstream-demand
  /// counts via the `requires:` graph. Tier 2 entries are sorted by
  /// descending downstream count.
  Future<VerifyReport> verifyProject();

  /// Remove an artifact pack.
  Future<bool> remove(final String packName);
}
