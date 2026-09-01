import 'package:agentic_executables_wire/agentic_executables_wire.dart';
import 'package:test/test.dart';

void main() {
  test('verify entries parse from both payload shapes', () {
    final bare = parseVerifyEntries([
      {
        'tier': 1,
        'tier_code': 'invariant_violation',
        'artifact': 'a.dart',
        'canonical': 'c1',
        'feature_id': 'entity.create',
        'message': 'handle reuse detected',
      },
    ]);
    final wrapped = parseVerifyEntries({'entries': [
      {
        'tier': 4,
        'tier_code': 'unreferenced_canonical',
        'artifact': '',
        'canonical': 'c2',
        'message': 'no artifact',
      },
    ]});
    expect(bare.single.tier, AeTier.invariantViolation);
    expect(wrapped.single.tier, AeTier.unreferencedCanonical);
  });

  test('blocking = T1/T2 without accepted drift; renderer orders blocking first', () {
    final gaps = parseVerifyEntries({
      'entries': [
        {'tier': 3, 'tier_code': 'partial_feature', 'artifact': 'x', 'canonical': 'c', 'message': 'partial'},
        {'tier': 4, 'tier_code': 'unreferenced_canonical', 'artifact': '', 'canonical': 'c2', 'message': 'no artifact'},
        {'tier': 1, 'tier_code': 'invariant_violation', 'artifact': 'a.dart', 'canonical': 'c1', 'feature_id': 'entity.create', 'message': 'handle reuse detected'},
        {'tier': 2, 'tier_code': 'upstream_blocker', 'artifact': '', 'canonical': 'c3', 'message': 'upstream', 'accepted_drift': true},
      ],
    });
    expect(hasBlockingGaps(gaps), isTrue);
    expect(gaps[0].blocking, isFalse); // T3 partial
    expect(gaps[2].blocking, isTrue); // T1
    expect(gaps[3].blocking, isFalse); // T2 but accepted drift

    final text = renderGapBeats(gaps);
    final lines = text.split('\n');
    expect(lines.first, 'verify: 1 blocking / 4 total');
    expect(lines[1], contains('[T1 invariant_violation] entity.create'));
  });

  test('round-trip through toMap keeps the wire shape stable', () {
    const entry = VerifyEntryWire(
      tier: AeTier.upstreamBlocker,
      artifact: 'a.dart',
      canonical: 'c',
      message: 'm',
      featureId: 'f',
      reason: 'evidence_failed',
      downstreamCount: 2,
    );
    final map = entry.toMap();
    expect(map['tier_code'], 'upstream_blocker');
    expect(map['accepted_drift'], null); // omitted unless true
    expect(VerifyEntryWire.fromMap(map).blocking, isTrue);
  });
}
