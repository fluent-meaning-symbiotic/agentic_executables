// ignore_for_file: lines_longer_than_80_chars

/// Verify wire: the tier-classified gap contract of `ae artifact verify`.
///
/// AE owns tier semantics (what T1–T4 mean, what counts as blocking); hosts
/// own the loop that consumes them. The JSON shape is the stable wire —
/// `VerifyEntry.toJson()` from `agentic_executables_core` round-trips through
/// [VerifyEntryWire.fromMap].
library;

/// Verification tiers, strongest first.
enum AeTier {
  invariantViolation(1, 'invariant_violation'),
  upstreamBlocker(2, 'upstream_blocker'),
  partialFeature(3, 'partial_feature'),
  unreferencedCanonical(4, 'unreferenced_canonical');

  const AeTier(this.tier, this.code);
  final int tier;
  final String code;

  static AeTier fromCode(String code) => AeTier.values.firstWhere(
        (t) => t.code == code,
        orElse: () => AeTier.partialFeature,
      );
}

/// One tier-classified gap (wire mirror of AE's `VerifyEntry`).
class VerifyEntryWire {
  const VerifyEntryWire({
    required this.tier,
    required this.artifact,
    required this.canonical,
    required this.message,
    this.featureId,
    this.reason,
    this.downstreamCount,
    this.acceptedDrift = false,
  });

  factory VerifyEntryWire.fromMap(Map<dynamic, dynamic> map) =>
      VerifyEntryWire(
        tier: AeTier.fromCode(map['tier_code']?.toString() ?? 'partial_feature'),
        artifact: map['artifact']?.toString() ?? '',
        canonical: map['canonical']?.toString() ?? '',
        message: map['message']?.toString() ?? '',
        featureId: map['feature_id']?.toString(),
        reason: map['reason']?.toString(),
        downstreamCount: map['downstream_count'] is int
            ? map['downstream_count'] as int
            : null,
        acceptedDrift: map['accepted_drift'] == true,
      );

  final AeTier tier;
  final String artifact;
  final String canonical;
  final String message;
  final String? featureId;

  /// Machine-readable cause (`no_evidence_link`, `evidence_failed`,
  /// `claimed_without_command`) so agents branch on data, not prose.
  final String? reason;
  final int? downstreamCount;
  final bool acceptedDrift;

  /// Machine-actionable: agents branch on this, not on prose.
  bool get blocking =>
      !acceptedDrift &&
      (tier == AeTier.invariantViolation || tier == AeTier.upstreamBlocker);

  Map<String, dynamic> toMap() => {
    'tier': tier.tier,
    'tier_code': tier.code,
    'artifact': artifact,
    'canonical': canonical,
    if (featureId != null) 'feature_id': featureId,
    'message': message,
    if (reason != null) 'reason': reason,
    if (downstreamCount != null) 'downstream_count': downstreamCount,
    if (acceptedDrift) 'accepted_drift': true,
  };
}

/// Parses a verify payload: either `{entries: [...]}` or a bare list.
List<VerifyEntryWire> parseVerifyEntries(Object? payload) {
  final list = switch (payload) {
    final Map m when m['entries'] is List => m['entries'] as List,
    final List l => l,
    _ => const [],
  };
  return [
    for (final e in list)
      if (e is Map) VerifyEntryWire.fromMap(e),
  ];
}

bool hasBlockingGaps(List<VerifyEntryWire> gaps) => gaps.any((g) => g.blocking);

String _clip(String s, [int max = 140]) =>
    s.length <= max ? s : '${s.substring(0, max)}…';

/// Compact tier-ordered beat text: one line per gap, blocking first.
///
/// A tiny model learns *what kind* of fix is needed, not just that
/// something failed.
String renderGapBeats(List<VerifyEntryWire> gaps) {
  if (gaps.isEmpty) return 'verify: clean';
  final sorted = [...gaps]
    ..sort((a, b) {
      if (a.blocking != b.blocking) return a.blocking ? -1 : 1;
      return a.tier.tier.compareTo(b.tier.tier);
    });
  final buf = StringBuffer()
    ..writeln('verify: ${gaps.where((g) => g.blocking).length} blocking / '
        '${gaps.length} total');
  for (final g in sorted) {
    final tag = g.acceptedDrift ? '${g.tier.code}(accepted)' : g.tier.code;
    buf.writeln(
      '[T${g.tier.tier} $tag] ${g.featureId ?? g.canonical}: '
      '${_clip(g.message)}${g.reason == null ? '' : ' (${g.reason})'}',
    );
  }
  return buf.toString().trimRight();
}
