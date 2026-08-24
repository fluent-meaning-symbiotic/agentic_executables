class HubConfig {
  const HubConfig({
    this.version = 1,
    this.remotes = const {},
    this.canonicalRemotes = const {},
  });

  final int version;
  final Map<String, HubRemote> remotes;

  /// Reserved for AE 3.x public canonical hub. Empty in 3.0.
  final Map<String, HubRemote> canonicalRemotes;

  Map<String, dynamic> toJson() => {
        'version': version,
        'remotes': remotes.map(
          (final key, final value) => MapEntry(key, value.toJson()),
        ),
        if (canonicalRemotes.isNotEmpty)
          'canonical_remotes': canonicalRemotes.map(
            (final key, final value) => MapEntry(key, value.toJson()),
          ),
      };

  String toYamlString() {
    final buffer = StringBuffer()..writeln('version: $version');
    if (remotes.isEmpty) {
      buffer.writeln('remotes: {}');
    } else {
      buffer.writeln('remotes:');
      for (final entry in remotes.entries) {
        buffer.writeln('  ${entry.key}:');
        buffer.writeln('    url: "${entry.value.url}"');
        buffer.writeln('    branch: "${entry.value.branch}"');
        buffer.writeln('    type: "${entry.value.type}"');
      }
    }
    if (canonicalRemotes.isNotEmpty) {
      buffer.writeln('canonical_remotes:');
      for (final entry in canonicalRemotes.entries) {
        buffer.writeln('  ${entry.key}:');
        buffer.writeln('    url: "${entry.value.url}"');
        buffer.writeln('    branch: "${entry.value.branch}"');
        buffer.writeln('    type: "${entry.value.type}"');
      }
    }
    return buffer.toString();
  }

  factory HubConfig.fromMap(final Map<dynamic, dynamic> map) {
    Map<String, HubRemote> readRemotes(final dynamic raw) {
      final out = <String, HubRemote>{};
      if (raw is Map) {
        for (final entry in raw.entries) {
          final key = entry.key.toString();
          if (entry.value is Map) {
            out[key] = HubRemote.fromMap(entry.value as Map);
          }
        }
      }
      return out;
    }

    return HubConfig(
      version: (map['version'] as int?) ?? 1,
      remotes: readRemotes(map['remotes']),
      canonicalRemotes: readRemotes(map['canonical_remotes']),
    );
  }
}

class HubRemote {
  const HubRemote({
    required this.url,
    this.branch = 'main',
    this.type = 'github',
  });

  final String url;
  final String branch;
  final String type;

  Map<String, dynamic> toJson() => {
        'url': url,
        'branch': branch,
        'type': type,
      };

  factory HubRemote.fromMap(final Map<dynamic, dynamic> map) => HubRemote(
        url: map['url']?.toString() ?? '',
        branch: map['branch']?.toString() ?? 'main',
        type: map['type']?.toString() ?? 'github',
      );
}

class HubStatus {
  const HubStatus({
    required this.path,
    required this.knowCount,
    required this.useCount,
    required this.packageCount,
    required this.config,
  });

  final String path;
  final int knowCount;
  final int useCount;
  final int packageCount;
  final HubConfig config;

  Map<String, dynamic> toJson() => {
        'path': path,
        'know_count': knowCount,
        'use_count': useCount,
        'package_count': packageCount,
        'config': config.toJson(),
      };
}

class HubInitInput {
  const HubInitInput({this.path, this.project = false});

  final String? path;
  final bool project;
}

class HubInitOutput {
  const HubInitOutput({
    required this.path,
    required this.created,
    required this.message,
  });

  final String path;
  final bool created;
  final String message;

  Map<String, dynamic> toJson() => {
        'path': path,
        'created': created,
        'message': message,
      };
}

class HubStatusInput {
  const HubStatusInput({this.hubPath});

  final String? hubPath;
}

class HubPullInput {
  const HubPullInput({
    this.hubPath,
    this.remote = 'origin',
    this.type,
    this.libraryId,
  });

  final String? hubPath;
  final String remote;
  final String? type;
  final String? libraryId;
}

class HubPullOutput {
  const HubPullOutput({
    required this.hubPath,
    required this.remote,
    required this.pulled,
    required this.message,
  });

  final String hubPath;
  final String remote;
  final List<String> pulled;
  final String message;

  Map<String, dynamic> toJson() => {
        'hub_path': hubPath,
        'remote': remote,
        'pulled': pulled,
        'message': message,
      };
}

class HubPushInput {
  const HubPushInput({this.hubPath, this.remote = 'origin'});

  final String? hubPath;
  final String remote;
}

class HubPushOutput {
  const HubPushOutput({
    required this.hubPath,
    required this.remote,
    required this.instructions,
    required this.message,
  });

  final String hubPath;
  final String remote;
  final String instructions;
  final String message;

  Map<String, dynamic> toJson() => {
        'hub_path': hubPath,
        'remote': remote,
        'instructions': instructions,
        'message': message,
      };
}
