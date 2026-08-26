import '../adapters/spec_importers.dart';
import '../models/canonical_matrix.dart';
import '../models/canonical_pack.dart';
import '../models/feature_id.dart';
import 'canonical_service.dart';

/// Result of importing an external spec document as a canonical.
class SpecImportResult {
  const SpecImportResult({
    required this.conceptId,
    required this.format,
    required this.featureCount,
    required this.ids,
    required this.skippedIds,
    required this.created,
  });

  final String conceptId;

  /// `document`, or a legacy compatibility format (`speckit` | `headings`).
  final String format;
  final int featureCount;
  final List<String> ids;

  /// Ids that already existed in a pre-existing canonical and were left
  /// untouched (merge semantics, never clobber).
  final List<String> skippedIds;
  final bool created;
}

  /// Imports external documents into canonical packs. Deterministic,
  /// no LLM. Merge-safe: existing rows are never overwritten; colliding ids
  /// are reported in [SpecImportResult.skippedIds].
class DefaultSpecImportService {
  DefaultSpecImportService({required this.canonicalService});

  final CanonicalService canonicalService;

  Future<SpecImportResult> importSpec(
    final String conceptId, {
    required final String markdown,
    String? title,
    final String format = 'auto',
  }) async {
    final parsed = switch (format) {
      'speckit' => SpecImportParser.parseSpeckit(markdown),
      'headings' => SpecImportParser.parseHeadings(markdown),
      'document' => SpecImportParser.parseDocument(markdown),
      _ => SpecImportParser.parse(markdown),
    };

    if (parsed.features.isEmpty) {
      throw StateError('No features could be parsed from the source document.');
    }

    // Deterministic id assignment with `spec.` namespace + collision suffixes.
    final usedIds = <String>{};
    final rows = <CanonicalFeature>[];
    for (final f in parsed.features) {
      var segment = f.suggestedId.isEmpty ? 'section' : f.suggestedId;
      var idStr = 'spec.$segment';
      var n = 2;
      while (usedIds.contains(idStr)) {
        idStr = 'spec.${segment}_$n';
        n++;
      }
      usedIds.add(idStr);
      rows.add(
        CanonicalFeature(
          id: FeatureId.parse(idStr),
          cells: {
            'spec': f.spec,
            if (f.invariant != null && f.invariant!.isNotEmpty)
              'invariant': f.invariant!,
          },
        ),
      );
    }

    final resolvedTitle =
        title ?? conceptId.split('.').last.replaceAll('_', ' ');

    final existing = await canonicalService.load(conceptId);
    final created = existing == null;
    if (existing == null) {
      await canonicalService.scaffold(
        conceptId,
        title: resolvedTitle,
        indexContent:
            '# $resolvedTitle\n\n'
            'Imported from an external spec document '
            '(format: ${parsed.format}).\n',
      );
    }

    final skipped = <String>[];
    final mergedFeatures = <CanonicalFeature>[];
    if (existing == null) {
      mergedFeatures.addAll(rows);
    } else {
      final existingIds =
          existing.matrix.features.map((final f) => f.id.toString()).toSet();
      for (final row in rows) {
        if (existingIds.contains(row.id.toString())) {
          skipped.add(row.id.toString());
        } else {
          mergedFeatures.add(row);
        }
      }
      mergedFeatures.addAll(existing.matrix.features);
    }

    final pack = CanonicalPack(
      meta: (existing?.meta ??
          CanonicalMeta(
            concept: conceptId,
            version: 1,
            title: resolvedTitle,
            license: const CanonicalLicense(
              spdx: 'CC-BY-4.0',
              url: 'https://creativecommons.org/licenses/by/4.0/',
            ),
            authors: const [],
            sources: const [],
            provenance: CanonicalProvenance(
              authored: CanonicalAuthored.hand,
              authoredAt: DateTime.now().toUtc(),
            ),
          )),
      indexContent: existing?.indexContent ??
          '# $resolvedTitle\n\n'
              'Imported from an external spec document '
              '(format: ${parsed.format}).\n',
      matrix: CanonicalMatrix(
        concept: conceptId,
        version: existing?.matrix.version ?? 1,
        columnSchema: const [
          CanonicalColumn(id: 'spec', type: 'text'),
          CanonicalColumn(id: 'invariant', type: 'text'),
        ],
        features: mergedFeatures,
      ),
    );
    await canonicalService.upsert(conceptId, pack);

    return SpecImportResult(
      conceptId: conceptId,
      format: parsed.format,
      featureCount: mergedFeatures.length - skipped.length,
      ids: mergedFeatures.map((final f) => f.id.toString()).toList(),
      skippedIds: skipped,
      created: created,
    );
  }
}
