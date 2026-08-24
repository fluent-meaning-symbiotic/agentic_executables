import 'dart:io';

import '../adapters/generic_heuristic_extractor.dart';
import '../ports/heuristic_extractor.dart';

/// Picks the first registered [HeuristicExtractor] whose `canHandle` returns
/// true for a given directory. Order matters: more-specific extractors should
/// come first when registered.
class HeuristicExtractorRegistry {
  HeuristicExtractorRegistry(this._extractors);

  final List<HeuristicExtractor> _extractors;

  static final GenericHeuristicExtractor _generic =
      const GenericHeuristicExtractor();

  /// Returns the first matching extractor. Falls back to the language-
  /// agnostic [GenericHeuristicExtractor] when no registered extractor
  /// recognizes [sourceDir], so ingestion never hard-fails on an unknown
  /// language — distillation is code-agnostic by design.
  Future<HeuristicExtractor> findFor(final Directory sourceDir) async {
    for (final extractor in _extractors) {
      if (await extractor.canHandle(sourceDir)) return extractor;
    }
    return _generic;
  }
}
