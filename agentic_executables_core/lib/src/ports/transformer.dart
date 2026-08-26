import '../models/ae_result.dart';

/// A single named, typed stage in an ETL transformation pipeline.
///
/// Composition SDK contract (ADR-free, consumer-driven — extracted from the
/// harness bridge usage): transformers are pure functions over a typed
/// input plus a read-only [TransformContext]; they never mutate global
/// state and never own a model. Pipelines compose them into verifiable
/// flows where every stage is individually testable and named for
/// attribution.
abstract interface class Transformer<In, Out> {
  /// Stable stage id used in pipeline reports and attribution rows.
  String get name;

  Future<Out> transform(final In input, final TransformContext context);
}

/// Read-only environment handed to every transformer in a run.
///
/// Carries run-scoped, non-secret metadata (working root, options) so
/// transformers stay reproducible: same input + same context = same output.
class TransformContext {
  const TransformContext({
    required this.runId,
    this.root,
    this.options = const {},
  });

  /// Unique-per-run identifier for logs and evidence records.
  final String runId;

  /// Filesystem root the pipeline operates inside (when applicable).
  final String? root;

  /// Run-scoped options; values must be JSON-encodable.
  final Map<String, Object?> options;

  T option<T>(final String key, final T orElse) => options[key] as T? ?? orElse;
}

/// One recorded step of a pipeline execution.
class PipelineStep<Out> {
  const PipelineStep({
    required this.name,
    required this.output,
    required this.elapsedMs,
  });

  final String name;
  final Out output;
  final int elapsedMs;
}

/// Ordered composition of transformers. Each stage receives the previous
/// stage's output; names and timings are preserved for attribution and
/// evidence.
class TransformerPipeline<In, Out> {
  TransformerPipeline(final List<Transformer<dynamic, dynamic>> stages)
    : _stages = _checked(stages);

  final List<Transformer<dynamic, dynamic>> _stages;

  static List<Transformer<dynamic, dynamic>> _checked(
    final List<Transformer<dynamic, dynamic>> stages,
  ) {
    if (stages.isEmpty) {
      throw ArgumentError.value(stages, 'stages', 'must not be empty');
    }
    return stages;
  }

  /// Number of composed stages.
  int get stageCount => _stages.length;

  /// Runs all stages in order and returns outputs with stage names/timings.
  ///
  /// Errors propagate unchanged — callers decide retry/classification
  /// policy; the pipeline stays mechanical.
  Future<AeResult<List<PipelineStep<Out>>>> run(
    final In input,
    final TransformContext context,
  ) async {
    final steps = <PipelineStep<Out>>[];
    var current = input;
    for (final stage in _stages) {
      try {
        final sw = Stopwatch()..start();
        current = await stage.transform(current, context);
        sw.stop();
        steps.add(PipelineStep<Out>(
            name: stage.name,
            output: current as Out,
            elapsedMs: sw.elapsedMilliseconds));
      } on Object catch (error, stackTrace) {
        return AeResult<List<PipelineStep<Out>>>.fail(
          code: 'transformer_stage_failed',
          message: 'stage "${stage.name}" failed: $error',
          details: stackTrace.toString(),
        );
      }
    }
    return AeResult<List<PipelineStep<Out>>>.ok(steps);
  }
}
