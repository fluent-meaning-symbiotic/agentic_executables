import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:test/test.dart';

void main() {
  group('AeCoreConfig v3 directory constants', () {
    test('canonical dir', () {
      expect(AeCoreConfig.hubCanonicalDir, 'canonical');
    });
    test('artifacts dir', () {
      expect(AeCoreConfig.hubArtifactsDir, 'artifacts');
    });
    test('artifact kinds', () {
      expect(AeCoreConfig.artifactKindLocal, 'local');
      expect(AeCoreConfig.artifactKindExternal, 'external');
      expect(AeCoreConfig.artifactKindUse, 'use');
    });
    test('canonical pack files', () {
      expect(AeCoreConfig.canonicalIndexFile, 'index.md');
      expect(AeCoreConfig.canonicalMatrixFile, 'matrix.yaml');
      expect(AeCoreConfig.canonicalMetaFile, 'meta.yaml');
      expect(AeCoreConfig.canonicalChangelogFile, 'CHANGELOG.md');
    });
    test('artifact pack files', () {
      expect(AeCoreConfig.artifactIndexFile, 'index.md');
      expect(AeCoreConfig.artifactMatrixFile, 'matrix.yaml');
      expect(AeCoreConfig.artifactMetaFile, 'meta.yaml');
      expect(AeCoreConfig.artifactPatternsFile, 'patterns.md');
      expect(AeCoreConfig.artifactDriftFile, 'drift.yaml');
    });
    test('framework version matches pubspec release', () {
      expect(AeCoreConfig.frameworkVersion, '3.2.0');
    });
  });
}
