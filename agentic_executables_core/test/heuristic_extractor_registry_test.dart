import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('HeuristicExtractorRegistry', () {
    late HeuristicExtractorRegistry registry;
    late Directory multiLangDir;

    setUp(() {
      registry = HeuristicExtractorRegistry(const [
        DartHeuristicExtractor(),
        RustHeuristicExtractor(),
        KotlinSwiftHeuristicExtractor(),
      ]);
      multiLangDir = Directory(
        p.join(
          Directory.current.path,
          'test',
          'fixtures',
          'multi_lang_minimal',
        ),
      );
    });

    test('findFor returns DartHeuristicExtractor for a Dart package', () async {
      final dir = Directory(p.join(multiLangDir.path, 'dart_pkg_a'));
      final ext = await registry.findFor(dir);
      expect(ext, isNotNull);
      expect(ext!.languageId, 'dart');
    });

    test('findFor returns RustHeuristicExtractor for a Rust crate', () async {
      final dir = Directory(p.join(multiLangDir.path, 'rust_crate_b'));
      final ext = await registry.findFor(dir);
      expect(ext!.languageId, 'rust');
    });

    test('findFor returns KotlinSwiftHeuristicExtractor for a Swift package',
        () async {
      final dir = Directory(p.join(multiLangDir.path, 'swift_pkg_c'));
      final ext = await registry.findFor(dir);
      expect(ext!.languageId, 'kotlin_swift');
    });

    test('findFor falls back to the generic extractor for unknown dirs',
        () async {
      final tmp = await Directory.systemTemp.createTemp('unknown_');
      try {
        final extractor = await registry.findFor(tmp);
        expect(extractor.languageId, 'generic');
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('integration: extract each sub-package via dispatched extractor',
        () async {
      final artifacts = <HeuristicArtifact>[];
      for (final sub in ['dart_pkg_a', 'rust_crate_b', 'swift_pkg_c']) {
        final dir = Directory(p.join(multiLangDir.path, sub));
        final ext = await registry.findFor(dir);
        expect(ext, isNotNull);
        artifacts.add(await ext!.extract(dir));
      }
      expect(artifacts.length, 3);
      expect(
        artifacts.map((final a) => a.languageId).toSet(),
        {'dart', 'rust', 'kotlin_swift'},
      );
      expect(artifacts.map((final a) => a.name).toSet(),
          {'dart_pkg_a', 'rust_crate_b', 'SwiftPkgC'});
    });
  });
}
