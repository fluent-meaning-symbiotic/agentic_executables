import 'dart:convert';
import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:path/path.dart' as path;

class AeMcpAdapter {
  AeMcpAdapter({
    required final String resourcesPath,
  })  : _registryClient = GitHubRawRegistryClient(),
        _definitionService = const DefaultAeDefinitionService(),
        _instructionService =
            DefaultAeInstructionService(FileDocumentStore(resourcesPath)),
        _validationService = const DefaultAeValidationService(),
        _generationService = const DefaultAeGenerationService(
          templateEngine: TemplateGenerationEngine(),
        ),
        _hubResolver = FileHubResolver() {
    _registryService = DefaultAeRegistryService(_registryClient);
    _hubService = DefaultAeHubService(
      _hubResolver,
      registryClient: _registryClient,
    );
  }

  final GitHubRawRegistryClient _registryClient;
  final AeDefinitionService _definitionService;
  final AeInstructionService _instructionService;
  final AeValidationService _validationService;
  late final AeRegistryService _registryService;
  final AeGenerationService _generationService;
  final FileHubResolver _hubResolver;
  late final AeHubService _hubService;

  Future<Map<String, dynamic>> definition(
    final Map<String, dynamic> params,
  ) async {
    final result = _definitionService.getDefinition();
    return _toEnvelope(result, (final data) => data.toJson());
  }

  Future<Map<String, dynamic>> instructions(
    final Map<String, dynamic> params,
  ) async {
    final contextRaw = params['context_type']?.toString() ?? '';
    final actionRaw = params['action']?.toString() ?? '';

    if (contextRaw.isEmpty) {
      return _validationError('Parameter "context_type" is required');
    }
    if (actionRaw.isEmpty) {
      return _validationError('Parameter "action" is required');
    }

    try {
      final context = AeContext.fromString(contextRaw);
      final action = AeAction.fromString(actionRaw);

      final result = await _instructionService.getInstructions(
        GetInstructionsInput(
          context: context,
          action: action,
        ),
      );
      return _toEnvelope(result, (final data) => data.toJson());
    } catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> verify(final Map<String, dynamic> params) async {
    final contextRaw = params['context_type']?.toString() ?? '';
    final actionRaw = params['action']?.toString() ?? '';

    if (contextRaw.isEmpty) {
      return _validationError('Parameter "context_type" is required');
    }
    if (actionRaw.isEmpty) {
      return _validationError('Parameter "action" is required');
    }

    try {
      final context = AeContext.fromString(contextRaw);
      final action = AeAction.fromString(actionRaw);

      final files = _typedListOfObjects(params, 'files_modified')
          .map(AeModifiedFile.fromJson)
          .toList(growable: false);

      final checklistRaw = _typedMap(params, 'checklist_completed');
      final checklist = <String, bool>{};
      for (final entry in checklistRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is! bool) {
          throw ArgumentError(
            'Parameter "checklist_completed.$key" must be a bool',
          );
        }
        checklist[key] = value;
      }

      final result = _validationService.verify(
        VerifyInput(
          context: context,
          action: action,
          filesModified: files,
          checklistCompleted: checklist,
        ),
      );

      return _toEnvelope(
        result,
        (final data) => {
          'context_type': context.value,
          'action': action.value,
          'verification': data.toJson(),
          'overall_status': data.overallPass ? 'PASS' : 'FAIL',
          'message': data.overallPass
              ? 'Implementation verification passed.'
              : 'Implementation verification failed. Review missing items.',
        },
      );
    } catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> evaluate(
    final Map<String, dynamic> params,
  ) async {
    final contextRaw = params['context_type']?.toString() ?? '';
    final actionRaw = params['action']?.toString() ?? '';

    if (contextRaw.isEmpty) {
      return _validationError('Parameter "context_type" is required');
    }
    if (actionRaw.isEmpty) {
      return _validationError('Parameter "action" is required');
    }

    try {
      final context = AeContext.fromString(contextRaw);
      final action = AeAction.fromString(actionRaw);

      final files = _typedListOfObjects(params, 'files_created')
          .map(AeCreatedFile.fromJson)
          .toList(growable: false);

      final sections = _typedList(params, 'sections_present')
          .map((final entry) => entry.toString())
          .toList(growable: false);

      final result = _validationService.evaluate(
        EvaluateInput(
          context: context,
          action: action,
          filesCreated: files,
          sectionsPresent: sections,
          validationStepsExists: _typedBool(
            params,
            'validation_steps_exists',
            defaultValue: false,
          ),
          integrationPointsDefined: _typedBool(
            params,
            'integration_points_defined',
            defaultValue: false,
          ),
          reversibilityIncluded:
              _typedBool(params, 'reversibility_included', defaultValue: false),
          hasMetaRules:
              _typedBool(params, 'has_meta_rules', defaultValue: false),
        ),
      );

      return _toEnvelope(
        result,
        (final data) => {
          'context_type': context.value,
          'action': action.value,
          'evaluation': data.toJson(),
          'overall_status': data.overallPass ? 'PASS' : 'FAIL',
          'message': data.overallPass
              ? 'Implementation meets AE compliance requirements.'
              : 'Implementation has issues that need to be addressed.',
        },
      );
    } catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> registry(
    final Map<String, dynamic> params,
  ) async {
    final operationRaw = params['operation']?.toString() ?? '';
    if (operationRaw.isEmpty) {
      return _validationError('Parameter "operation" is required');
    }

    final AeRegistryOperation operation;
    try {
      operation = AeRegistryOperation.fromString(operationRaw);
    } catch (error) {
      return _validationError(error.toString());
    }

    switch (operation) {
      case AeRegistryOperation.submitToRegistry:
        final libraryUrl = params['library_url']?.toString() ?? '';
        final libraryId = params['library_id']?.toString() ?? '';
        final files = _parseRegistryFiles(params['ae_use_files']);

        final result = await _registryService.submitToRegistry(
          RegistrySubmitInput(
            libraryUrl: libraryUrl,
            libraryId: libraryId,
            aeUseFiles: files,
          ),
        );

        return _toEnvelope(result, (final data) => data.toJson());

      case AeRegistryOperation.getFromRegistry:
        final libraryId = params['library_id']?.toString() ?? '';
        final actionRaw = params['action']?.toString() ?? '';
        if (actionRaw.isEmpty) {
          return _validationError('Parameter "action" is required');
        }

        final AeAction action;
        try {
          action = AeAction.fromString(actionRaw);
        } catch (error) {
          return _validationError(error.toString());
        }
        final result = await _registryService.getFromRegistry(
          RegistryGetInput(libraryId: libraryId, action: action),
        );

        return _toEnvelope(result, (final data) => data.toJson());

      case AeRegistryOperation.bootstrapLocalRegistry:
        final aeUsePath = params['ae_use_path']?.toString() ?? '';
        final result = _registryService.bootstrapLocalRegistry(
          RegistryBootstrapLocalInput(aeUsePath: aeUsePath),
        );
        return _toEnvelope(result, (final data) => data.toJson());
    }
  }

  Future<Map<String, dynamic>> generate(
    final Map<String, dynamic> params,
  ) async {
    final libraryId = params['library_id']?.toString() ?? '';
    final libraryRoot = params['library_root']?.toString() ?? '';
    if (libraryId.isEmpty || libraryRoot.isEmpty) {
      return _validationError(
        'Parameters "library_id" and "library_root" are required',
      );
    }

    final outputDir =
        params['output_dir']?.toString() ?? path.join(libraryRoot, 'ae_use');
    final dryRun = _typedBool(params, 'dry_run', defaultValue: false);

    final modeRaw = (params['engine']?.toString() ?? 'auto').toLowerCase();
    if (modeRaw != 'auto' && modeRaw != 'template') {
      return _validationError(
        'Parameter "engine" must be one of: auto, template',
      );
    }

    const mode = AeGenerationEngineMode.template;

    final result = await _generationService.generate(
      GenerateInput(
        libraryId: libraryId,
        libraryRoot: libraryRoot,
        outputDir: outputDir,
        engineMode: mode,
        dryRun: dryRun,
      ),
    );

    if (!result.success || result.data == null) {
      return _toEnvelope(result, (final data) => data.toJson());
    }

    final generated = result.data!;
    final writtenFiles = <String>[];

    if (!dryRun) {
      final directory = Directory(outputDir);
      await directory.create(recursive: true);
      for (final file in generated.files) {
        final diskPath = path.join(outputDir, file.path);
        await File(diskPath).writeAsString(file.content);
        writtenFiles.add(diskPath);
      }
    }

    final warnings = <String>[...result.warnings];
    for (final file in generated.files) {
      if (file.content.contains('TODO:')) {
        warnings.add('Unresolved placeholder markers found in ${file.path}');
      }
    }

    return {
      'success': true,
      'data': {
        ...generated.toJson(),
        'output_dir': outputDir,
        'dry_run': dryRun,
        'written_files': writtenFiles,
        'engine_requested': modeRaw,
        'engine_resolved': 'template',
      },
      'warnings': warnings,
      'meta': result.meta,
    };
  }

  Future<Map<String, dynamic>> hub(
    final Map<String, dynamic> params,
  ) async {
    final operationRaw = params['operation']?.toString() ?? '';
    if (operationRaw.isEmpty) {
      return _validationError('Parameter "operation" is required');
    }

    const validOps = ['init', 'status', 'pull', 'push'];
    if (!validOps.contains(operationRaw)) {
      return _validationError(
        'Parameter "operation" must be one of: ${validOps.join(', ')}',
      );
    }

    try {
      switch (operationRaw) {
        case 'init':
          final hubPath = params['path']?.toString();
          final project = _typedBool(params, 'project', defaultValue: false);
          final result = await _hubService.init(
            HubInitInput(path: hubPath, project: project),
          );
          return _toEnvelope(result, (final data) => data.toJson());

        case 'status':
          final hubPath = params['hub_path']?.toString();
          final result = await _hubService.status(
            HubStatusInput(hubPath: hubPath),
          );
          return _toEnvelope(result, (final data) => data.toJson());

        case 'pull':
          final hubPath = params['hub_path']?.toString();
          final remote = params['remote']?.toString() ?? 'origin';
          final libraryId = params['library_id']?.toString();
          final type = params['type']?.toString();
          final result = await _hubService.pull(
            HubPullInput(
              hubPath: hubPath,
              remote: remote,
              libraryId: libraryId,
              type: type,
            ),
          );
          return _toEnvelope(result, (final data) => data.toJson());

        case 'push':
          final hubPath = params['hub_path']?.toString();
          final remote = params['remote']?.toString() ?? 'origin';
          final result = await _hubService.push(
            HubPushInput(hubPath: hubPath, remote: remote),
          );
          return _toEnvelope(result, (final data) => data.toJson());

        default:
          return _validationError('Unknown operation: $operationRaw');
      }
    } catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> init(
    final Map<String, dynamic> params,
  ) async {
    final root = params['root']?.toString() ?? Directory.current.path;
    final strict = _typedBool(params, 'strict', defaultValue: false);
    final hubPath = await _hubResolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return {
        'success': false,
        'error': {
          'code': 'no_hub',
          'message': 'No .ae_hub at $root',
        },
      };
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final registry = HeuristicExtractorRegistry(const [
      DartHeuristicExtractor(),
      RustHeuristicExtractor(),
      KotlinSwiftHeuristicExtractor(),
    ]);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: registry,
    );
    final ingested = <String>[];
    final skipped = <String>[];
    final rootDir = Directory(root);
    await for (final entity in rootDir.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final base = path.basename(entity.path);
      if (base.startsWith('.')) continue;
      final handler = await registry.findFor(entity);
      if (handler.languageId != 'generic') {
        final name = await svc.ingest(entity);
        ingested.add(name);
      } else {
        // Generic fallback means findFor never returns null; a directory
        // only worth ingesting at init time is one a specific extractor
        // recognizes. Unknown dirs are skipped.
        skipped.add(entity.path);
      }
    }
    if ((await registry.findFor(rootDir)).languageId != 'generic') {
      ingested.add(await svc.ingest(rootDir));
    }
    if (strict && skipped.isNotEmpty) {
      return {
        'success': false,
        'error': {
          'code': 'unhandled_subdirs',
          'message': 'No extractor for ${skipped.length} subdirectories',
          'details': {'skipped': skipped},
        },
      };
    }
    return {
      'success': true,
      'data': {
        'hub_path': hubPath,
        'ingested': ingested,
        'skipped_count': skipped.length,
      },
    };
  }

  Future<Map<String, dynamic>> status(
    final Map<String, dynamic> params,
  ) async {
    final root = params['root']?.toString() ?? Directory.current.path;
    final packName = params['pack']?.toString();
    final tierFilterRaw = params['tier']?.toString();
    final hubPath = await _hubResolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return {
        'success': false,
        'error': {'code': 'no_hub', 'message': 'No hub at $root'},
      };
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: HeuristicExtractorRegistry(const []),
    );
    final report = packName != null
        ? await svc.verifyOne(packName)
        : await svc.verifyProject();
    final entries = tierFilterRaw == null
        ? report.entries
        : report.entries
            .where((final e) => e.tier.tier.toString() == tierFilterRaw)
            .toList();
    return {
      'success': true,
      'data': {
        'hub_path': hubPath,
        'entries': entries.map((final e) => e.toJson()).toList(),
        'tier_counts': {
          for (final entry in report.tierCounts.entries)
            entry.key.code: entry.value,
        },
      },
    };
  }

  Future<Map<String, dynamic>> sync(
    final Map<String, dynamic> params,
  ) async {
    final root = params['root']?.toString() ?? Directory.current.path;
    final packName = params['pack']?.toString();
    final prune = _typedBool(params, 'prune', defaultValue: false);
    final hubPath = await _hubResolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return {
        'success': false,
        'error': {'code': 'no_hub', 'message': 'No hub at $root'},
      };
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: HeuristicExtractorRegistry(const []),
    );
    final drift = DefaultDriftService(
      artifactStore: artStore,
      canonicalStore: canStore,
    );
    final names = packName != null ? [packName] : await svc.list();
    final results = <Map<String, dynamic>>[];
    final pruned = <String>[];
    for (final name in names) {
      try {
        final outcome = await svc.syncOne(name, prune: prune);
        if (outcome.pruned) {
          pruned.add(name);
          results.add({'pack': name, 'pruned': true});
          continue;
        }
        final report =
            await drift.buildReport(name, generatedBy: 'ae sync (mcp)');
        results.add({
          'pack': name,
          'changed': outcome.changed,
          'code_drift_count': report.codeDrift.length,
          'intent_drift_count': report.intentDrift.length,
        });
      } on ArgumentError catch (e) {
        results.add({'pack': name, 'error': e.message?.toString()});
      }
    }
    return {
      'success': true,
      'data': {
        'hub_path': hubPath,
        'results': results,
        'pruned': pruned,
      },
    };
  }

  Future<Map<String, dynamic>> artifact(
    final Map<String, dynamic> params,
  ) async {
    final operation = params['operation']?.toString() ?? '';
    if (operation.isEmpty) {
      return _validationError('Parameter "operation" is required');
    }
    const validOps = [
      'list',
      'verify',
      'link',
      'upgrade-canonical',
      'mark-evidence'
    ];
    if (!validOps.contains(operation)) {
      return _validationError(
        'operation must be one of: ${validOps.join(', ')}',
      );
    }
    final root = params['root']?.toString() ?? Directory.current.path;
    final hubPath = await _hubResolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return {
        'success': false,
        'error': {'code': 'no_hub', 'message': 'No hub at $root'},
      };
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: HeuristicExtractorRegistry(const [
        DartHeuristicExtractor(),
        RustHeuristicExtractor(),
        KotlinSwiftHeuristicExtractor(),
      ]),
    );
    try {
      switch (operation) {
        case 'list':
          return {
            'success': true,
            'data': {'artifacts': await svc.list()},
          };

        case 'verify':
          final pack = params['pack']?.toString();
          final strict = _typedBool(params, 'strict', defaultValue: false);
          final runTests = _typedBool(params, 'run_tests', defaultValue: false);
          if (pack == null) return _validationError('Missing "pack"');
          final report = await svc.verifyOne(pack, runTests: runTests);
          if (strict && report.hasBlockingTiers) {
            return {
              'success': false,
              'error': {
                'code': 'verify_failed',
                'message': 'Pack $pack has blocking-tier entries (strict)',
                'details': report.toJson(),
              },
            };
          }
          return {'success': true, 'data': report.toJson()};

        case 'mark-evidence':
          final pack = params['pack']?.toString();
          final feature = params['feature_id']?.toString();
          final testCommand = params['test_command']?.toString();
          if (pack == null) return _validationError('Missing "pack"');
          if (feature == null) return _validationError('Missing "feature_id"');
          if (testCommand == null) {
            return _validationError('Missing "test_command"');
          }
          try {
            final result = await svc.markEvidence(
              pack,
              feature,
              testCommand: testCommand,
              location: params['location']?.toString(),
              notes: params['notes']?.toString(),
              impl: ImplStatus.fromString(
                params['impl'] == null ? 'done' : params['impl'].toString(),
              ),
            );
            return {
              'success': true,
              'data': {
                'pack': result.pack,
                'feature_id': result.featureId,
                'cell': result.cell.toJson(),
              },
            };
          } on ArgumentError catch (e) {
            final msg = e.message?.toString() ?? e.toString();
            return {
              'success': false,
              'error': {
                'code': msg.contains('not found in pack')
                    ? 'feature_not_found'
                    : 'artifact_not_found',
                'message': msg,
              },
            };
          }

        case 'link':
          final pack = params['pack']?.toString();
          final canonicalRaw = params['canonical']?.toString();
          if (pack == null || canonicalRaw == null) {
            return _validationError('Missing "pack" and/or "canonical"');
          }
          final ref = CanonicalReference.parse(canonicalRaw);
          await svc.link(
            pack,
            ref.conceptId,
            lockedVersion: ref.lockedVersion,
          );
          await svc.materialize(pack);
          return {
            'success': true,
            'data': {'pack': pack, 'canonical': ref.toString()},
          };

        case 'upgrade-canonical':
          final pack = params['pack']?.toString();
          final concept = params['canonical']?.toString();
          final toRaw = params['to']?.toString();
          if (pack == null || concept == null || toRaw == null) {
            return _validationError('Missing pack/canonical/to');
          }
          final v = int.tryParse(toRaw);
          if (v == null) return _validationError('"to" must be int');
          await svc.upgradeCanonical(pack, concept, toVersion: v);
          await svc.materialize(pack);
          return {
            'success': true,
            'data': {'pack': pack, 'canonical': '$concept@v$v'},
          };

        default:
          return _validationError('Unknown operation: $operation');
      }
    } catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> canonical(
    final Map<String, dynamic> params,
  ) async {
    final operation = params['operation']?.toString() ?? '';
    if (operation.isEmpty) {
      return _validationError('Parameter "operation" is required');
    }
    const validOps = [
      'init',
      'scaffold',
      'list',
      'snapshot',
      'diff',
      'import',
      'distill',
      'distill-merge',
      'accept-concept',
    ];
    if (!validOps.contains(operation)) {
      return _validationError(
        'operation must be one of: ${validOps.join(', ')}',
      );
    }
    final root = params['root']?.toString() ?? Directory.current.path;
    final hubPath = await _hubResolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return {
        'success': false,
        'error': {'code': 'no_hub', 'message': 'No hub at $root'},
      };
    }
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultCanonicalService(store: canStore);
    try {
      switch (operation) {
        case 'init':
          final concept = params['concept']?.toString();
          final title = params['title']?.toString();
          if (concept == null || concept.isEmpty) {
            return _validationError('Missing "concept"');
          }
          if (title == null || title.isEmpty) {
            return _validationError('Missing "title"');
          }
          final pack = await svc.scaffold(concept, title: title);
          return {
            'success': true,
            'data': {
              'concept': pack.meta.concept,
              'version': pack.meta.version,
            },
          };

        case 'scaffold':
          final concept = params['concept']?.toString();
          final title = params['title']?.toString();
          final overwrite =
              _typedBool(params, 'overwrite', defaultValue: false);
          final update = _typedBool(params, 'update', defaultValue: false);
          if (concept == null || concept.isEmpty) {
            return _validationError('Missing "concept"');
          }
          final fromArtifacts = _coerceStringList(params['from_artifact']);
          if (fromArtifacts.isEmpty) {
            return _validationError(
              'Missing "from_artifact" (string or list of strings).',
            );
          }
          if (update && overwrite) {
            return _validationError(
              '"update" and "overwrite" are mutually exclusive.',
            );
          }

          final artStore = FileArtifactStore(hubPath);
          final missing = <String>[];
          for (final name in fromArtifacts) {
            if (!await artStore.exists(name)) missing.add(name);
          }
          if (missing.isNotEmpty) {
            return {
              'success': false,
              'error': {
                'code': 'artifact_not_found',
                'message': 'artifact_not_found: ${missing.join(', ')}',
              },
            };
          }

          if (update) {
            final renamesRaw = params['renames'];
            final renames = <List<String>>[];
            if (renamesRaw is List) {
              for (final entry in renamesRaw) {
                if (entry is Map &&
                    entry['from'] is String &&
                    entry['to'] is String) {
                  renames
                      .add([entry['from'].toString(), entry['to'].toString()]);
                } else {
                  return _validationError(
                    'malformed renames entry; expected [{from, to}, ...]',
                  );
                }
              }
            } else if (renamesRaw != null) {
              return _validationError(
                'renames must be a list of {from, to} objects.',
              );
            }
            try {
              final report = await svc.scaffoldUpdate(
                concept,
                artifactNames: fromArtifacts,
                artifactStore: artStore,
                renames: renames,
              );
              return {
                'success': true,
                'data': {
                  'concept': concept,
                  'mode': 'update',
                  'added': report.added,
                  'removed': report.removed,
                  'renamed': [
                    for (final pair in report.renamed)
                      {'from': pair[0], 'to': pair[1]},
                  ],
                  'unchanged': report.unchanged,
                  'from_artifacts': fromArtifacts,
                },
              };
            } on StateError catch (e) {
              if (e.message.contains('canonical_not_found')) {
                return {
                  'success': false,
                  'error': {
                    'code': 'canonical_not_found',
                    'message': e.message,
                  },
                };
              }
              rethrow;
            } on ArgumentError catch (e) {
              final msg = e.message?.toString() ?? '';
              if (msg.contains('rename_collision') ||
                  msg.contains('rename_missing') ||
                  msg.contains('rename_malformed')) {
                return _validationError(msg);
              }
              if (msg.contains('artifact_not_found')) {
                return _validationError(msg);
              }
              return _validationError(msg);
            }
          }

          // Original non-update path. title is required; preserve existing
          // canonical_exists pre-check before invoking the service.
          if (title == null || title.isEmpty) {
            return _validationError('Missing "title"');
          }
          if (!overwrite && await svc.load(concept) != null) {
            return {
              'success': false,
              'error': {
                'code': 'canonical_exists',
                'message': 'canonical_exists: $concept already exists; pass '
                    'overwrite=true to replace.',
              },
            };
          }
          final pack = await svc.scaffoldFromArtifact(
            concept,
            title: title,
            artifactNames: fromArtifacts,
            artifactStore: artStore,
            overwrite: overwrite,
          );
          return {
            'success': true,
            'data': {
              'concept': pack.meta.concept,
              'version': pack.meta.version,
              'feature_count': pack.matrix.features.length,
              'authored': pack.meta.provenance.authored.value,
              'from_artifacts': fromArtifacts,
            },
          };

        case 'list':
          return {
            'success': true,
            'data': {'concepts': await svc.list()},
          };

        case 'snapshot':
          final concept = params['concept']?.toString();
          if (concept == null) return _validationError('Missing "concept"');
          final dir = await svc.snapshot(concept);
          return {
            'success': true,
            'data': {'concept': concept, 'snapshot_dir': dir},
          };

        case 'diff':
          final concept = params['concept']?.toString();
          if (concept == null) return _validationError('Missing "concept"');
          int? parseVer(final v) {
            if (v == null) return null;
            final s = v.toString();
            if (s.isEmpty || s == 'current') return null;
            return int.tryParse(s.startsWith('v') ? s.substring(1) : s);
          }
          final diff = await svc.diff(
            concept,
            fromVersion: parseVer(params['from']),
            toVersion: parseVer(params['to']),
          );
          return {'success': true, 'data': diff.toJson()};

        case 'import':
          final from = params['from']?.toString();
          final asConcept = params['as']?.toString();
          if (from == null || asConcept == null) {
            return _validationError('Missing "from" and/or "as"');
          }
          final pack = await svc.import(from, asConceptId: asConcept);
          return {
            'success': true,
            'data': {
              'imported_as': asConcept,
              'concept_in_meta': pack.meta.concept,
            },
          };

        case 'distill':
        case 'distill-merge':
          return await _canonicalDistill(
            params: params,
            hubPath: hubPath,
            canonicalService: svc,
          );

        case 'accept-concept':
          final concept = params['concept']?.toString();
          final id = params['id']?.toString();
          final fromProposal = params['from_proposal']?.toString();
          if (concept == null || concept.isEmpty) {
            return _validationError('Missing "concept"');
          }
          if (id == null || id.isEmpty) {
            return _validationError('Missing "id"');
          }
          if (fromProposal == null || fromProposal.isEmpty) {
            return _validationError('Missing "from_proposal"');
          }
          try {
            final result = await svc.acceptConcept(
              concept,
              newId: id,
              fromProposal: fromProposal,
            );
            return {
              'success': true,
              'data': {
                'concept': concept,
                'accepted_id': result.acceptedId,
                'from_proposal': result.proposalName,
              },
            };
          } on ProposalNotFoundException catch (e) {
            return {
              'success': false,
              'error': {'code': 'proposal_not_found', 'message': e.toString()},
            };
          } on IdCollisionException catch (e) {
            final detail = e.isTombstone
                ? ' The row was previously removed; reuse will be supported by `--revive` (planned).'
                : '';
            return {
              'success': false,
              'error': {'code': 'id_collision', 'message': '$e$detail'},
            };
          } on StateError catch (e) {
            if (e.message.contains('canonical_not_found')) {
              return {
                'success': false,
                'error': {'code': 'canonical_not_found', 'message': e.message},
              };
            }
            rethrow;
          }

        default:
          return _validationError('Unknown operation: $operation');
      }
    } catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> _canonicalDistill({
    required final Map<String, dynamic> params,
    required final String hubPath,
    required final DefaultCanonicalService canonicalService,
  }) async {
    final concept = params['concept']?.toString();
    if (concept == null || concept.isEmpty) {
      return _validationError('Missing "concept"');
    }
    final mergeMode =
        (params['operation']?.toString() ?? '') == 'distill-merge';

    // ---- Phase 2: merge a returned draft (host agent did the model work).
    if (mergeMode) {
      final rawOutput = params['output'];
      if (rawOutput == null) {
        return _validationError(
          'Missing "output" (the ae.canonical.draft.v1 JSON from the agent)',
        );
      }
      final Map<String, dynamic> decoded;
      if (rawOutput is Map) {
        decoded = rawOutput.map(
          (final k, final v) => MapEntry(k.toString(), v),
        );
      } else {
        try {
          decoded = jsonDecode(rawOutput.toString()) as Map<String, dynamic>;
        } on FormatException catch (e) {
          return {
            'success': false,
            'error': {
              'code': 'draft_parse_failed',
              'message': 'Draft output is not valid JSON: ${e.message}',
            },
          };
        }
      }
      if (decoded['schema']?.toString() != 'ae.canonical.draft.v1') {
        return {
          'success': false,
          'error': {
            'code': 'draft_schema_mismatch',
            'message': 'Expected schema "ae.canonical.draft.v1", got '
                '"${decoded['schema']}"',
          },
        };
      }

      final DistillationOutput output;
      try {
        output = DistillationOutput.fromMap(decoded);
      } catch (e) {
        return {
          'success': false,
          'error': {
            'code': 'draft_invalid',
            'message': 'Draft output failed validation: \$e',
          },
        };
      }
      if (output.conceptId != concept) {
        return {
          'success': false,
          'error': {
            'code': 'draft_concept_mismatch',
            'message':
                'Draft is for concept "${output.conceptId}", expected "\$concept"',
          },
        };
      }

      try {
        final mergeReport = await canonicalService.mergeDistillationDetailed(
          concept,
          output,
        );
        await canonicalService.writeProposalsFile(
          concept,
          proposals: mergeReport.proposedConcepts,
          executorUsed: 'host_agent',
        );
        final merged = mergeReport.pack;
        return {
          'success': true,
          'data': {
            'merged': true,
            'concept': concept,
            'version': merged.meta.version,
            'feature_count': mergeReport.featureCountAfterMerge,
            'feature_count_received': mergeReport.featureCountReceived,
            'feature_count_after_merge': mergeReport.featureCountAfterMerge,
            'executor_used': 'host_agent',
            if (mergeReport.proposedConcepts.isNotEmpty)
              'proposed_concepts': mergeReport.proposedConcepts
                  .map((final c) => c.toJson())
                  .toList(growable: false),
          },
          'warnings': mergeReport.warnings,
        };
      } on IdNotInMatrixException catch (e) {
        return {
          'success': false,
          'error': {'code': 'id_not_in_matrix', 'message': e.toString()},
        };
      }
    }

    // ---- Phase 1: emit delegation instructions (AE never calls a model).
    final pack = params['pack']?.toString();
    if (pack == null || pack.isEmpty) {
      return _validationError('Missing "pack"');
    }
    final mode = params['mode']?.toString() ?? 'upsert';
    if (mode != 'upsert' && mode != 'refine') {
      return _validationError('"mode" must be "upsert" or "refine"');
    }

    final artStore = FileArtifactStore(hubPath);
    final artifact = await artStore.load(pack);
    if (artifact == null) {
      return {
        'success': false,
        'error': {
          'code': 'artifact_not_found',
          'message': 'Artifact pack not found: \$pack',
        },
      };
    }

    final existing = await canonicalService.load(concept);
    final emission = const DefaultDistillDelegationService().buildEmission(
      pack: pack,
      concept: concept,
      artifact: artifact,
      existingCanonical: existing,
    );

    return {
      'success': true,
      'data': {
        'mode': 'delegate',
        'concept': concept,
        'pack': pack,
        'seed_rows': emission.task.matrixSeedRows.length,
        'instructions': emission.instructions,
        'next': "Delegate these instructions to the coding agent, then call "
            'ae_canonical with operation "distill-merge", passing the '
            "agent's JSON response as 'output' and this 'concept'.",
      },
    };
  }

  Future<Map<String, dynamic>> package(
    final Map<String, dynamic> params,
  ) async {
    final operation = params['operation']?.toString() ?? '';
    if (operation.isEmpty) {
      return _validationError('Parameter "operation" is required');
    }
    const validOps = ['resolve', 'validate'];
    if (!validOps.contains(operation)) {
      return _validationError(
        'operation must be one of: ${validOps.join(', ')}',
      );
    }

    const service = DefaultAePackageService();

    try {
      switch (operation) {
        case 'resolve':
          final packageId = params['package']?.toString() ?? '';
          if (packageId.isEmpty) {
            return _validationError(
              'Parameter "package" is required for resolve',
            );
          }
          final target = params['target']?.toString() ?? 'linux';
          final format = params['format']?.toString() ?? 'json';
          final packageRoot = params['package_root']?.toString();
          final result = await service.resolve(
            PackageResolveInput(
              packageId: packageId,
              target: target,
              format: format,
              packageRoot: packageRoot,
            ),
          );
          return _toEnvelope(result, (final data) => data);

        case 'validate':
          final raw = params['instructions'];
          if (raw == null) {
            return _validationError(
              'Parameter "instructions" is required for validate',
            );
          }
          Map<String, dynamic> instructions;
          if (raw is Map) {
            instructions = raw.map(
              (final key, final value) => MapEntry(key.toString(), value),
            );
          } else if (raw is String) {
            final source = raw.trim();
            if (source.isEmpty) {
              return _validationError(
                'Parameter "instructions" must not be empty',
              );
            }
            try {
              final fileCandidate = File(source);
              final content = await fileCandidate.exists()
                  ? await fileCandidate.readAsString()
                  : source;
              final decoded = jsonDecode(content);
              if (decoded is! Map) {
                return _validationError(
                  'Parameter "instructions" must decode to an object',
                );
              }
              instructions = decoded.map(
                (final key, final value) => MapEntry(key.toString(), value),
              );
            } on FormatException catch (error) {
              return _validationError(
                'Failed to parse instructions JSON: ${error.message}',
              );
            }
          } else {
            return _validationError(
              'Parameter "instructions" must be a JSON object or string',
            );
          }
          final result = await service.validate(
            PackageValidateInput(instructions: instructions),
          );
          return _toEnvelope(result, (final data) => data);

        default:
          return _validationError('Unknown operation: $operation');
      }
    } on Object catch (error) {
      return _validationError(error.toString());
    }
  }

  Future<Map<String, dynamic>> doctor(
    final Map<String, dynamic> params,
  ) async {
    final target = params['target']?.toString().trim() ?? '';
    if (target.isEmpty) {
      return _validationError('Parameter "target" is required');
    }

    try {
      final doctor = AeDoctor();
      final output = await doctor.run(skillTarget: target);
      return {
        'success': true,
        'data': output.toJson(),
        'warnings': const <String>[],
        'meta': const {'operation': 'doctor'},
      };
    } on Object catch (error) {
      return _validationError(error.toString());
    }
  }

  void close() {
    _registryClient.close();
  }

  Map<String, dynamic> _toEnvelope<T>(
    final AeResult<T> result,
    final Map<String, dynamic> Function(T data) serializer,
  ) {
    if (!result.success || result.data == null) {
      return {
        'success': false,
        'data': const {},
        'error': {
          'code': result.error?.code ?? 'tool_failed',
          'message': result.error?.message ?? 'Tool failed',
          if (result.error?.details != null) 'details': result.error?.details,
        },
        'warnings': result.warnings,
        'meta': result.meta,
      };
    }

    return {
      'success': true,
      'data': serializer(result.data as T),
      'warnings': result.warnings,
      'meta': result.meta,
    };
  }

  Map<String, dynamic> _validationError(final String message) => {
        'success': false,
        'data': const {},
        'error': {
          'code': 'validation_error',
          'message': message,
        },
        'warnings': const [],
        'meta': const {},
      };

  List<Map<String, dynamic>> _typedListOfObjects(
    final Map<String, dynamic> params,
    final String key,
  ) {
    final value = params[key];
    if (value == null) {
      return const [];
    }
    if (value is String) {
      throw ArgumentError(
        'Parameter "$key" must be a typed list of objects. '
        'String-encoded JSON is no longer supported.',
      );
    }
    if (value is! List) {
      throw ArgumentError('Parameter "$key" must be a list of objects');
    }

    final output = <Map<String, dynamic>>[];
    for (final entry in value) {
      if (entry is! Map) {
        throw ArgumentError('Parameter "$key" must contain only objects');
      }
      output.add(
        entry.map(
          (final mapKey, final mapValue) =>
              MapEntry(mapKey.toString(), mapValue),
        ),
      );
    }
    return output;
  }

  Map<String, dynamic> _typedMap(
    final Map<String, dynamic> params,
    final String key,
  ) {
    final value = params[key];
    if (value == null) {
      return const {};
    }
    if (value is String) {
      throw ArgumentError(
        'Parameter "$key" must be a typed object. '
        'String-encoded JSON is no longer supported.',
      );
    }
    if (value is! Map) {
      throw ArgumentError('Parameter "$key" must be an object');
    }
    return value.map(
      (final mapKey, final mapValue) => MapEntry(mapKey.toString(), mapValue),
    );
  }

  List _typedList(final Map<String, dynamic> params, final String key) {
    final value = params[key];
    if (value == null) {
      return const [];
    }
    if (value is String) {
      throw ArgumentError(
        'Parameter "$key" must be a typed list. '
        'String-encoded JSON is no longer supported.',
      );
    }
    if (value is! List) {
      throw ArgumentError('Parameter "$key" must be a list');
    }
    return value;
  }

  bool _typedBool(
    final Map<String, dynamic> params,
    final String key, {
    required final bool defaultValue,
  }) {
    final value = params[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is! bool) {
      throw ArgumentError('Parameter "$key" must be a bool');
    }
    return value;
  }

  List<String> _parseRegistryFiles(final Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is String) {
      return value
          .split(',')
          .map((final entry) => entry.trim())
          .where((final entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (value is List) {
      return value
          .map((final entry) => entry.toString())
          .where((final entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    throw ArgumentError(
      'Parameter "ae_use_files" must be a comma-separated string or list',
    );
  }

  /// Accepts either a single string (one artifact) or a list of strings
  /// (multiple artifacts) for parameters that map to a CLI repeatable
  /// option like `--from-artifact`.
  List<String> _coerceStringList(final Object? value) {
    if (value == null) return const [];
    if (value is String) {
      if (value.isEmpty) return const [];
      return [value];
    }
    if (value is List) {
      return value
          .map((final entry) => entry.toString())
          .where((final entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    throw ArgumentError(
      'Expected a string or list of strings; got ${value.runtimeType}',
    );
  }
}
