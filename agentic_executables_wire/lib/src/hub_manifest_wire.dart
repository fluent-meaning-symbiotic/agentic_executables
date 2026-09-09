// ignore_for_file: lines_longer_than_80_chars

/// Hub manifest wire contract (`ae.hub_manifest.v1`).
///
/// The distribution seam for knowledge packs: a manifest maps a pack id to
/// its canonical file, content hash, and version — enough for any consumer
/// (local hub today, remote hub later) to verify WHAT it holds without
/// embedding AE. LOCAL HUB ONLY today: remote distribution (fetch/push,
/// trust, signing) is NAMED, NOT BUILT — the manifest shape is the stable
/// seam those verbs will land on.
///
/// Wire owns SYNTAX only, same rules as `ae.knowledge_pack.v1`:
/// - unknown schema → THROW (fail loudly on unknown shapes);
/// - corrupted entries → kept as NAMED data (never guessed).
library;

import 'meaning_tree_export.dart';

/// Envelope schema for the hub manifest.
const hubManifestSchema = 'ae.hub_manifest.v1';

/// Exact entry keys. Anything else is an unknown shape: loud failure.
const hubManifestEntryKeys = <String>{'pack', 'file', 'sha256', 'version'};

final RegExp _sha256Pattern = RegExp(r'^[0-9a-fA-F]{64}$');

/// One manifest entry: pack id → canonical file hash + version.
class HubManifestEntry {
  const HubManifestEntry({
    required this.pack,
    required this.file,
    required this.sha256,
    required this.version,
  });

  /// Pack id (stable key of the manifest).
  final String pack;

  /// Canonical pack file path, relative to the manifest's directory.
  final String file;

  /// SHA-256 of the canonical file bytes (64 hex chars), verbatim.
  final String sha256;

  /// Pack version (int or string), verbatim.
  final dynamic version;

  Map<String, dynamic> toMap() => {
    'pack': pack,
    'file': file,
    'sha256': sha256,
    'version': version,
  };
}

/// A parsed hub manifest.
class HubManifest {
  const HubManifest({required this.entries});

  final List<HubManifestEntry> entries;

  Map<String, HubManifestEntry> get byPack => {
    for (final e in entries) e.pack: e,
  };

  factory HubManifest.fromMap(Map<dynamic, dynamic> map) => HubManifest(
    entries: [
      for (final e in (map['entries'] as List? ?? const []))
        if (e is Map)
          HubManifestEntry(
            pack: e['pack']?.toString() ?? '',
            file: e['file']?.toString() ?? '',
            sha256: e['sha256']?.toString() ?? '',
            version: e['version'],
          ),
    ],
  );

  Map<String, dynamic> toMap() => {
    'schema': hubManifestSchema,
    'entries': [for (final e in entries) e.toMap()],
  };
}

/// Result of validating a hub manifest: parsed entries + named errors.
class HubManifestValidation {
  const HubManifestValidation({required this.manifest, required this.errors});

  /// Manifest with every VALID entry (invalid ones are not guesses —
  /// they are named in [errors]).
  final HubManifest manifest;

  /// Entries that could not be validated, kept as NAMED data: each names
  /// the entry index/pack and a reason.
  final List<Map<String, dynamic>> errors;

  bool get isValid => errors.isEmpty;
}

/// Validates a `ae.hub_manifest.v1` [manifest].
///
/// Deterministic and LLM-free. Unknown schema or a non-list `entries`
/// field THROW (fail loudly on unknown shapes). Corrupted entries
/// (not an object, missing/empty fields, malformed sha256, unknown keys,
/// duplicate pack ids) are skipped and returned as named data.
HubManifestValidation validateHubManifest(Map<dynamic, dynamic> manifest) {
  final schema = manifest['schema']?.toString() ?? '';
  if (schema != hubManifestSchema) {
    throw StateError(
      'ae wire: unknown hub manifest schema "$schema" '
      '(expected "$hubManifestSchema") — fail loudly on unknown shapes',
    );
  }
  final rawEntries = manifest['entries'];
  if (rawEntries is! List) {
    throw StateError(
      'ae wire: hub manifest "entries" must be a list '
      '— fail loudly on unknown shapes',
    );
  }

  final entries = <HubManifestEntry>[];
  final errors = <Map<String, dynamic>>[];
  final seenPacks = <String>{};

  for (var i = 0; i < rawEntries.length; i++) {
    final raw = rawEntries[i];
    if (raw is! Map) {
      errors.add({'index': i, 'reason': 'entry is not an object'});
      continue;
    }
    final pack = raw['pack']?.toString() ?? '';
    final file = raw['file']?.toString() ?? '';
    final sha256 = raw['sha256']?.toString() ?? '';
    final version = raw['version'];
    final unknownKeys = raw.keys
        .map((k) => k.toString())
        .where((k) => !hubManifestEntryKeys.contains(k))
        .toList()
      ..sort();
    if (unknownKeys.isNotEmpty) {
      errors.add({
        'index': i,
        if (pack.isNotEmpty) 'pack': pack,
        'reason': 'unknown entry keys: ${unknownKeys.join(', ')}',
      });
      continue;
    }
    if (pack.isEmpty || file.isEmpty || sha256.isEmpty || version == null) {
      errors.add({
        'index': i,
        'pack': pack,
        'reason': 'entry missing pack, file, sha256, or version',
      });
      continue;
    }
    if (!_sha256Pattern.hasMatch(sha256)) {
      errors.add({
        'index': i,
        'pack': pack,
        'reason': 'sha256 is not 64 hex chars',
      });
      continue;
    }
    if (!seenPacks.add(pack)) {
      errors.add({'index': i, 'pack': pack, 'reason': 'duplicate pack id'});
      continue;
    }
    entries.add(
      HubManifestEntry(pack: pack, file: file, sha256: sha256, version: version),
    );
  }

  return HubManifestValidation(
    manifest: HubManifest(entries: entries),
    errors: errors,
  );
}

/// Deterministic canonical form of a hub manifest: recursively key-sorted
/// JSON. Same input → byte-identical output, always.
String canonicalHubManifestForm(Map<dynamic, dynamic> manifest) =>
    canonicalJsonForm(manifest);
