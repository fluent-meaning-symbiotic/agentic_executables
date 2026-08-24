import '../adapters/distill_prompt.dart';
import '../models/artifact_pack.dart';
import '../models/canonical_matrix.dart';
import '../models/canonical_pack.dart';
import '../models/distillation_task.dart';

/// What AE emits when asked to distill: a delegation package. AE never
/// calls a model — the host agent (Claude Code, pi, Codex, Cursor…) reads
/// [instructions] and the embedded task JSON, does the work, and returns
/// an `ae.canonical.draft.v1` JSON that the operator merges back via
/// `ae canonical distill --from-output` (CLI) / op `distill-merge` (MCP).
class DistillEmission {
  const DistillEmission({required this.task, required this.instructions});

  /// Machine-readable task (`ae.distillation.task.v1`). Agents may use it
  /// directly instead of the prose prompt.
  final DistillationTask task;

  /// Human/agent-readable delegation instructions embedding the task.
  final String instructions;
}

/// Builds delegation emissions for the distill workflow. Pure — no
/// process spawning, no HTTP, no model access by design.
class DefaultDistillDelegationService {
  const DefaultDistillDelegationService();

  /// Compose the emission from an already-loaded artifact pack and the
  /// (possibly absent) existing canonical.
  DistillEmission buildEmission({
    required final String pack,
    required final String concept,
    required final ArtifactPack artifact,
    required final CanonicalPack? existingCanonical,
  }) {
    final conceptVersion = existingCanonical?.meta.version ?? 1;
    final seed =
        existingCanonical?.matrix.features ?? const <CanonicalFeature>[];
    final language = artifact.meta.extractor.split('_').first;
    final files = artifact.meta.source.files
        .map((final f) => f.path)
        .toList(growable: false);

    final task = DistillationTask(
      conceptId: concept,
      conceptVersion: conceptVersion,
      sourceArtifact: DistillationSourceArtifact(
        name: pack,
        language: language,
        files: files,
        structuralSummary: artifact.indexContent,
      ),
      matrixSeedRows: seed,
    );

    return DistillEmission(
      task: task,
      instructions: buildDistillInstructions(task),
    );
  }
}
