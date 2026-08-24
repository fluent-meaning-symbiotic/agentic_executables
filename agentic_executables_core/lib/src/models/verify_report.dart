import 'feature_id.dart';

enum VerifyTier {
  invariantViolation(1, 'invariant_violation'),
  upstreamBlocker(2, 'upstream_blocker'),
  partialFeature(3, 'partial_feature'),
  unreferencedCanonical(4, 'unreferenced_canonical');

  const VerifyTier(this.tier, this.code);
  final int tier;
  final String code;
}

class VerifyEntry {
  const VerifyEntry({
    required this.tier,
    required this.artifact,
    required this.canonical,
    required this.featureId,
    required this.message,
    this.reason,
    this.downstreamCount,
    this.acceptedDrift = false,
  });

  final VerifyTier tier;
  final String artifact;
  final String canonical;
  final FeatureId? featureId;
  final String message;

  /// Machine-readable cause so agents branch on data, not prose:
  /// - `no_evidence_link`: the claim exists but no evidence command is
  ///   recorded. This does NOT mean the behavior is untested — search the
  ///   existing suite and link what exists before writing new tests.
  /// - `evidence_failed`: a recorded evidence command ran and failed; the
  ///   claim is contradicted by its own proof.
  /// - `claimed_without_command`: tests cell says yes but no provenance
  ///   command is recorded (legacy row).
  final String? reason;
  final int? downstreamCount;
  final bool acceptedDrift;

  Map<String, dynamic> toJson() => {
        'tier': tier.tier,
        'tier_code': tier.code,
        'artifact': artifact,
        'canonical': canonical,
        if (featureId != null) 'feature_id': featureId.toString(),
        'message': message,
        if (reason != null) 'reason': reason,
        if (downstreamCount != null) 'downstream_count': downstreamCount,
        if (acceptedDrift) 'accepted_drift': true,
      };
}

class VerifyReport {
  const VerifyReport({required this.entries});

  final List<VerifyEntry> entries;

  List<VerifyEntry> byTier(final VerifyTier tier) =>
      entries.where((final e) => e.tier == tier).toList(growable: false);

  Map<VerifyTier, int> get tierCounts {
    final counts = <VerifyTier, int>{};
    for (final tier in VerifyTier.values) {
      counts[tier] = byTier(tier).length;
    }
    return counts;
  }

  /// True if any Tier 1 (invariant violation) or Tier 2 (upstream blocker)
  /// entries exist that are NOT marked accepted in drift.yaml.
  bool get hasBlockingTiers => entries.any(
        (final e) =>
            (e.tier == VerifyTier.invariantViolation ||
                e.tier == VerifyTier.upstreamBlocker) &&
            !e.acceptedDrift,
      );

  Map<String, dynamic> toJson() => {
        'entries': entries.map((final e) => e.toJson()).toList(growable: false),
        'tier_counts': {
          for (final entry in tierCounts.entries) entry.key.code: entry.value,
        },
      };
}
