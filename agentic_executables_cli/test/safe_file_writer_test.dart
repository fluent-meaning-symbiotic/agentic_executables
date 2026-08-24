import 'dart:io';

import 'package:agentic_executables_cli/src/io/safe_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('safe_writer_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('adds a new file when target does not exist', () async {
    final writer = SafeFileWriter();
    final target = p.join(tmp.path, 'new.txt');
    final batch = await writer.writeAll(
      requests: [FileWriteRequest(path: target, content: 'hello')],
      options: const SafeWriteOptions(),
    );
    expect(batch.files.single.status, FileWriteStatus.added);
    expect(await File(target).readAsString(), 'hello');
  });

  test('blocks changing an existing file under noOverwrite', () async {
    final writer = SafeFileWriter();
    final target = p.join(tmp.path, 'existing.txt');
    await File(target).writeAsString('original');

    final batch = await writer.writeAll(
      requests: [FileWriteRequest(path: target, content: 'replacement')],
      options: const SafeWriteOptions(noOverwrite: true),
    );
    expect(batch.files.single.status, FileWriteStatus.blocked);
    expect(batch.hasBlocked, isTrue);
    expect(await File(target).readAsString(), 'original',
        reason: 'blocked write must not touch the file');
  });

  test('updates an existing file when overwrite is permitted', () async {
    final writer = SafeFileWriter();
    final target = p.join(tmp.path, 'existing.txt');
    await File(target).writeAsString('original');

    final batch = await writer.writeAll(
      requests: [FileWriteRequest(path: target, content: 'replacement')],
      options: const SafeWriteOptions(),
    );
    expect(batch.files.single.status, FileWriteStatus.updated);
    expect(await File(target).readAsString(), 'replacement');
  });

  test('check mode reports intended status without touching disk', () async {
    final writer = SafeFileWriter();
    final target = p.join(tmp.path, 'existing.txt');
    await File(target).writeAsString('original');

    final batch = await writer.writeAll(
      requests: [FileWriteRequest(path: target, content: 'replacement')],
      options: const SafeWriteOptions(check: true),
    );
    expect(batch.files.single.status, FileWriteStatus.updated);
    expect(batch.hasChanges, isTrue);
    expect(await File(target).readAsString(), 'original',
        reason: '--check must never modify the file');
  });

  test('unchanged content reports unchanged and writes nothing', () async {
    final writer = SafeFileWriter();
    final target = p.join(tmp.path, 'same.txt');
    await File(target).writeAsString('same');

    final batch = await writer.writeAll(
      requests: [FileWriteRequest(path: target, content: 'same')],
      options: const SafeWriteOptions(),
    );
    expect(batch.files.single.status, FileWriteStatus.unchanged);
    expect(batch.wroteAny, isFalse);
  });
}
