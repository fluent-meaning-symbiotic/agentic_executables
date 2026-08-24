/// Deterministic parsers that turn external specification documents
/// (GitHub Spec Kit specs, ADRs, plain structured markdown) into AE
/// canonical feature rows. No LLM involved — same contract as the
/// heuristic extractors.
///
/// Strategy (spec §6.7 spirit): make ANY existing spec format eligible
/// for verification instead of asking authors to re-write it as a
/// canonical by hand. See docs_site/docs/ae-3/roadmap.md.
library;

/// One parsed candidate feature row.
class ParsedSpecFeature {
  const ParsedSpecFeature({
    required this.suggestedId,
    required this.spec,
    this.invariant,
  });

  /// Dot-separated id segment suggestion WITHOUT namespace prefix, e.g.
  /// `fr001` or `user_login`. The importer prefixes with `spec.` and
  /// de-duplicates collisions deterministically.
  final String suggestedId;
  final String spec;
  final String? invariant;
}

/// Result of parsing an external spec document.
class ParsedSpec {
  const ParsedSpec({required this.format, required this.features});

  /// `speckit` | `headings`
  final String format;
  final List<ParsedSpecFeature> features;
}

class SpecImportParser {
  /// Auto-detects the format and parses [markdown].
  static ParsedSpec parse(final String markdown) {
    if (_looksLikeSpeckit(markdown)) {
      return parseSpeckit(markdown);
    }
    return parseHeadings(markdown);
  }

  static bool _looksLikeSpeckit(final String markdown) {
    final reqLine = RegExp(r'^\s*(FR|NFR|REQ)[- ]?\d+\s*[:.]', multiLine: true);
    final storyHeading =
        RegExp(r'^#{2,4}\s*User Story', caseSensitive: false, multiLine: true);
    return reqLine.hasMatch(markdown) || storyHeading.hasMatch(markdown);
  }

  /// GitHub Spec Kit-style specs:
  ///   - `FR-1:` / `NFR-2.` / `REQ-3:` requirement lines become features;
  ///     following indented bullets enrich the spec text; bullets containing
  ///     MUST/SHALL become the invariant.
  ///   - Otherwise `### User Story: ...` sections (US1...) become features,
  ///     with `#### Acceptance Scenario`/`- [ ]`/`SHOULD|MUST` bullets folded
  ///     into spec/invariant cells.
  static ParsedSpec parseSpeckit(final String markdown) {
    final features = <ParsedSpecFeature>[];
    final lines = markdown.split('\n');

    final reqPattern = RegExp(r'^\s*(FR|NFR|REQ)[- ]?(\d+)\s*[:.]\s*(.*)$');
    var i = 0;
    while (i < lines.length) {
      final m = reqPattern.firstMatch(lines[i]);
      if (m == null) {
        i++;
        continue;
      }
      final label = '${m.group(1)!.toLowerCase()}${m.group(2)!}';
      final buffer = StringBuffer(m.group(3) ?? '');
      final invariants = <String>[];
      i++;
      // Consume following bullet lines belonging to this requirement.
      while (i < lines.length) {
        final line = lines[i];
        final bullet = RegExp(r'^\s*[-*]\s+(.*)$').firstMatch(line);
        final isNextReq = reqPattern.firstMatch(line) != null;
        final isHeading = line.startsWith('#');
        if (isNextReq || isHeading || (bullet == null && line.trim().isEmpty)) {
          break;
        }
        if (bullet != null) {
          final text = _clean(bullet.group(1)!);
          if (_isInvariantish(text)) {
            invariants.add(text);
          } else {
            buffer.write(' ${_stripMarker(text)}');
          }
        } else if (line.trim().isNotEmpty) {
          buffer.write(' ${_clean(line)}');
        }
        i++;
      }
      features.add(
        ParsedSpecFeature(
          suggestedId: label,
          spec: _clean(buffer.toString()),
          invariant: invariants.isEmpty ? null : invariants.join('; '),
        ),
      );
    }

    if (features.isNotEmpty) {
      return ParsedSpec(format: 'speckit', features: features);
    }

    // User-story fallback: each `### User Story` section becomes a feature.
    final storyStart =
        RegExp(r'^#{2,4}\s*User Story', caseSensitive: false, multiLine: true);
    if (!storyStart.hasMatch(markdown)) {
      return parseHeadings(markdown);
    }
    final matches = storyStart.allMatches(markdown).toList();
    for (var s = 0; s < matches.length; s++) {
      final startIdx = matches[s].end;
      final endIdx =
          s + 1 < matches.length ? matches[s + 1].start : markdown.length;
      final headingTitle = _clean(matches[s].group(1) ?? 'user story');
      final body = markdown.substring(startIdx, endIdx);
      final specLines = <String>[];
      final invariants = <String>[];
      for (final raw in body.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final text = _clean(line.replaceFirst(RegExp(r'^[-*\d.)\s]+'), ''));
        if (text.isEmpty) continue;
        if (_isInvariantish(text)) {
          invariants.add(text);
        } else {
          specLines.add(_stripMarker(text));
        }
      }
      features.add(
        ParsedSpecFeature(
          suggestedId: slugify(
            headingTitle.isEmpty ? 'story_${s + 1}' : headingTitle,
          ),
          spec: specLines.join(' '),
          invariant: invariants.isEmpty ? null : invariants.join('; '),
        ),
      );
    }
    return ParsedSpec(format: 'speckit', features: features);
  }

  /// Generic structured markdown / ADR: every `##`+ heading (except the
  /// document title H1) becomes one feature; body text folds into `spec`,
  /// MUST/SHALL bullets fold into `invariant`.
  static ParsedSpec parseHeadings(final String markdown) {
    final features = <ParsedSpecFeature>[];
    final lines = markdown.split('\n');
    String? currentTitle;
    final body = <String>[];

    void flush() {
      if (currentTitle == null) return;
      final spec = <String>[];
      final invariants = <String>[];
      for (final raw in body) {
        final text = _clean(raw);
        if (text.isEmpty) continue;
        if (_isInvariantish(text)) {
          // Split the line into sentences so only the MUST/SHALL clauses
          // become invariants and the rest stays in `spec`.
          for (final sentence in _splitSentences(text)) {
            if (_isInvariantish(sentence)) {
              invariants.add(_stripMarker(sentence));
            } else {
              spec.add(_stripMarker(sentence));
            }
          }
        } else {
          spec.add(_stripMarker(text));
        }
      }
      if (spec.isEmpty && invariants.isEmpty) return;
      features.add(
        ParsedSpecFeature(
          suggestedId: slugify(currentTitle),
          spec: spec.join(' '),
          invariant: invariants.isEmpty ? null : invariants.join('; '),
        ),
      );
    }

    for (final line in lines) {
      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        if (level >= 2) {
          flush();
          currentTitle = _clean(heading.group(2)!);
          body.clear();
          continue;
        }
        // H1 = document title; ignore.
        flush();
        currentTitle = null;
        body.clear();
        continue;
      }
      if (currentTitle != null) body.add(line);
    }
    flush();
    return ParsedSpec(format: 'headings', features: features);
  }

  /// Lowercase `[a-z0-9_]` slug from a heading; collapses non-alphanumerics
  /// to `_`, trims leading digits (FeatureId segments must start with a
  /// letter), prefixes `sec_` when nothing usable remains.
  static String slugify(final String input) {
    var s = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (s.startsWith(RegExp(r'[0-9]'))) s = 'sec_$s';
    if (s.isEmpty) s = 'section';
    return s.length > 48 ? s.substring(0, 48) : s;
  }

  /// Splits on sentence boundaries while keeping short fragments intact.
  static List<String> _splitSentences(final String text) {
    final parts = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((final s) => s.trim())
        .where((final s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? [text] : parts;
  }

  static bool _isInvariantish(final String text) {
    final t = text.toLowerCase();
    return t.contains('must') ||
        t.contains('shall') ||
        t.contains('muss') ||
        t.startsWith('[ ]') ||
        t.startsWith('[x]');
  }

  static String _stripMarker(final String text) =>
      text.replaceFirst(RegExp(r'^\[[ x]\]\s*'), '');

  static String _clean(final String text) => text.trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
}
