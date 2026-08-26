import 'package:test/test.dart';

import 'package:agentic_executables_core/agentic_executables_core.dart';

class _Upper implements Transformer<String, String> {
  @override
  String get name => 'upper';

  @override
  Future<String> transform(
    final String input,
    final TransformContext context,
  ) async =>
      input.toUpperCase();
}

class _Suffix implements Transformer<String, String> {
  const _Suffix(this.suffix);
  final String suffix;

  @override
  String get name => 'suffix';

  @override
  Future<String> transform(
    final String input,
    final TransformContext context,
  ) async =>
      input + context.option('suffix', suffix);
}

class _Boom implements Transformer<String, String> {
  @override
  String get name => 'boom';

  @override
  Future<String> transform(
    final String input,
    final TransformContext context,
  ) async =>
      throw StateError('exploded');
}

void main() {
  test('pipeline composes stages in order with names and timings', () async {
    final pipeline = TransformerPipeline<String, String>([
      _Upper(),
      const _Suffix('!'),
    ]);
    final result = await pipeline.run(
      'ae',
      const TransformContext(runId: 'run-1'),
    );
    expect(result.success, isTrue);
    final steps = result.data!;
    expect(steps.map((s) => s.name), ['upper', 'suffix']);
    expect(steps.last.output, 'AE!');
    for (final s in steps) {
      expect(s.elapsedMs, greaterThanOrEqualTo(0));
    }
  });

  test('transform context options are readable with defaults', () async {
    final pipeline = TransformerPipeline<String, String>([
      const _Suffix('?'),
    ]);
    final custom = await pipeline.run(
      'ae',
      const TransformContext(runId: 'r', options: {'suffix': '#'}),
    );
    expect(custom.data!.last.output, 'ae#');

    final defaulted = await pipeline.run(
      'ae',
      const TransformContext(runId: 'r'),
    );
    expect(defaulted.data!.last.output, 'ae?');
  });

  test('stage failure surfaces as coded failure naming the stage', () async {
    final pipeline = TransformerPipeline<String, String>([
      _Upper(),
      _Boom(),
    ]);
    final result = await pipeline.run(
      'ae',
      const TransformContext(runId: 'r'),
    );
    expect(result.success, isFalse);
    expect(result.error!.code, 'transformer_stage_failed');
    expect(result.error!.message, contains('"boom"'));
    expect(result.error!.message, contains('exploded'));
  });

  test('empty pipelines are rejected at construction', () {
    expect(() => TransformerPipeline<String, String>([]), throwsArgumentError);
  });
}
