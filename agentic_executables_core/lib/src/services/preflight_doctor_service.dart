import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/ae_core_config.dart';

enum DoctorStatus {
  ok('ok'),
  warn('warn'),
  fail('fail');

  const DoctorStatus(this.value);

  final String value;
}

class DoctorCheck {
  const DoctorCheck({
    required this.id,
    required this.label,
    required this.status,
    required this.critical,
    required this.diagnostic,
    required this.fixCommand,
  });

  final String id;
  final String label;
  final DoctorStatus status;
  final bool critical;
  final String diagnostic;
  final String fixCommand;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'status': status.value,
        'critical': critical,
        'diagnostic': diagnostic,
        'fix_command': fixCommand,
      };
}

class DoctorOutput {
  const DoctorOutput({required this.checks});

  final List<DoctorCheck> checks;

  bool get hasCriticalFailure => checks.any(
        (final check) => check.critical && check.status == DoctorStatus.fail,
      );

  Map<String, dynamic> toJson() => {
        'overall_status': hasCriticalFailure ? 'fail' : 'pass',
        if (hasCriticalFailure) 'failure_code': 'doctor_checks_failed',
        'checks': checks.map((final check) => check.toJson()).toList(
              growable: false,
            ),
      };
}

/// Preflight doctor: runs `ae doctor`-style sanity checks against the local
/// environment (Dart SDK, skill target writability, registry reachability).
/// AE never calls models, so there is nothing model-related to probe.
/// Pure, side-effect-free except for the temp-file write probe
/// scoped to [skillTarget] and a short HTTP HEAD-equivalent GET against the
/// registry probe URL.
class AeDoctor {
  AeDoctor({
    this.environment,
    this.registryProbeUrl,
  });

  final Map<String, String>? environment;
  final String? registryProbeUrl;

  Future<DoctorOutput> run({required final String skillTarget}) async {
    final checks = <DoctorCheck>[
      await _checkDartSdk(),
      await _checkSkillTarget(skillTarget),
      await _checkRegistryReachability(),
    ];

    return DoctorOutput(checks: checks);
  }

  Future<DoctorCheck> _checkDartSdk() async {
    final binaryPath = _resolveBinaryPath('dart');
    if (binaryPath == null) {
      return const DoctorCheck(
        id: 'dart_available',
        label: 'Dart SDK',
        status: DoctorStatus.warn,
        critical: false,
        diagnostic: 'dart binary was not found in PATH',
        fixCommand: 'Install Dart SDK and ensure `dart` is in PATH',
      );
    }

    try {
      final result = await Process.run(binaryPath, const ['--version']);
      if (result.exitCode == 0) {
        return DoctorCheck(
          id: 'dart_available',
          label: 'Dart SDK',
          status: DoctorStatus.ok,
          critical: false,
          diagnostic: 'dart SDK is available at $binaryPath',
          fixCommand: 'dart --version',
        );
      }

      return DoctorCheck(
        id: 'dart_available',
        label: 'Dart SDK',
        status: DoctorStatus.warn,
        critical: false,
        diagnostic:
            'dart --version exited with ${result.exitCode}: ${result.stderr.toString().trim()}',
        fixCommand: 'Reinstall Dart SDK or fix PATH',
      );
    } catch (error) {
      return DoctorCheck(
        id: 'dart_available',
        label: 'Dart SDK',
        status: DoctorStatus.warn,
        critical: false,
        diagnostic: 'Failed to execute dart --version: $error',
        fixCommand: 'Install Dart SDK and ensure `dart` is in PATH',
      );
    }
  }

  Future<DoctorCheck> _checkSkillTarget(final String target) async {
    final directory = Directory(target);
    final probe = File(
      path.join(
        directory.path,
        '.ae_doctor_write_probe_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    try {
      await directory.create(recursive: true);
      await probe.writeAsString('ok');
      await probe.delete();
      return DoctorCheck(
        id: 'skill_target_writable',
        label: 'Skill target writable',
        status: DoctorStatus.ok,
        critical: true,
        diagnostic: 'Skill target is writable: ${directory.path}',
        fixCommand: 'ls -ld ${directory.path}',
      );
    } catch (error) {
      if (await probe.exists()) {
        await probe.delete();
      }
      return DoctorCheck(
        id: 'skill_target_writable',
        label: 'Skill target writable',
        status: DoctorStatus.fail,
        critical: true,
        diagnostic: 'Cannot write to skill target ${directory.path}: $error',
        fixCommand: 'mkdir -p ${directory.path} && chmod u+w ${directory.path}',
      );
    }
  }

  Future<DoctorCheck> _checkRegistryReachability() async {
    final url = registryProbeUrl ??
        AeCoreConfig.buildGitHubRawUrl(
          owner: AeCoreConfig.registryOwner,
          repo: AeCoreConfig.registryRepo,
          branch: AeCoreConfig.registryBranch,
          path: 'README.md',
        );

    if (url == 'mock://ok') {
      return const DoctorCheck(
        id: 'registry_reachable',
        label: 'AE registry reachable',
        status: DoctorStatus.ok,
        critical: true,
        diagnostic: 'Registry probe marked reachable by mock://ok',
        fixCommand: 'n/a',
      );
    }

    if (url == 'mock://fail') {
      return const DoctorCheck(
        id: 'registry_reachable',
        label: 'AE registry reachable',
        status: DoctorStatus.fail,
        critical: true,
        diagnostic: 'Registry probe marked unreachable by mock://fail',
        fixCommand: 'Check network access and registry URL configuration',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      await response.drain<void>();

      final reachable = response.statusCode >= 200 && response.statusCode < 500;
      if (reachable) {
        return DoctorCheck(
          id: 'registry_reachable',
          label: 'AE registry reachable',
          status: DoctorStatus.ok,
          critical: true,
          diagnostic:
              'Registry endpoint reachable (${response.statusCode}) at $url',
          fixCommand: 'curl -I $url',
        );
      }

      return DoctorCheck(
        id: 'registry_reachable',
        label: 'AE registry reachable',
        status: DoctorStatus.fail,
        critical: true,
        diagnostic: 'Registry returned status ${response.statusCode} for $url',
        fixCommand: 'curl -I $url',
      );
    } catch (error) {
      return DoctorCheck(
        id: 'registry_reachable',
        label: 'AE registry reachable',
        status: DoctorStatus.fail,
        critical: true,
        diagnostic: 'Failed to reach registry endpoint: $error',
        fixCommand: 'Check network access and run: curl -I $url',
      );
    } finally {
      client.close(force: true);
    }
  }

  String? _resolveBinaryPath(final String binaryName) {
    if (binaryName.contains(Platform.pathSeparator)) {
      return File(binaryName).existsSync() ? binaryName : null;
    }

    final pathEnv = (environment ?? Platform.environment)['PATH'];
    if (pathEnv == null || pathEnv.isEmpty) {
      return null;
    }

    final candidates = pathEnv
        .split(Platform.isWindows ? ';' : ':')
        .where((final segment) => segment.isNotEmpty)
        .map((final segment) => '$segment${Platform.pathSeparator}$binaryName');

    if (Platform.isWindows) {
      for (final candidate in candidates) {
        final exe = File('$candidate.exe');
        if (exe.existsSync()) {
          return exe.path;
        }
        final cmd = File('$candidate.cmd');
        if (cmd.existsSync()) {
          return cmd.path;
        }
      }
      return null;
    }

    for (final candidate in candidates) {
      final file = File(candidate);
      if (file.existsSync()) {
        return file.path;
      }
    }

    return null;
  }
}
