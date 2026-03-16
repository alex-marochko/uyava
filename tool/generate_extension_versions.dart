import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const Map<String, HostConfig> _hostConfigs = <String, HostConfig>{
  'devtools': HostConfig(
    channel: 'devtools',
    outputPackage: 'uyava_devtools_extension',
    outputRelativePath: 'lib/src/version.g.dart',
    packageFields: <String, String>{
      'uyava_devtools_extension': 'extensionVersion',
      'uyava_core': 'coreVersion',
      'uyava_protocol': 'protocolVersion',
    },
  ),
  'desktop': HostConfig(
    channel: 'desktop',
    outputPackage: 'uyava_desktop',
    outputRelativePath: 'lib/src/version.g.dart',
    packageFields: <String, String>{
      'uyava_desktop': 'desktopVersion',
      'uyava_core': 'coreVersion',
      'uyava_protocol': 'protocolVersion',
    },
  ),
};

Future<void> main(List<String> args) async {
  final targets = _resolveTargets(args);
  final repoRoot = Directory.current.path;
  for (final target in targets) {
    final HostConfig? config = _hostConfigs[target];
    if (config == null) {
      stderr.writeln(
        'Unknown host "$target". Valid options: ${_hostConfigs.keys.join(', ')}',
      );
      exitCode = 64;
      return;
    }
    final bool ok = await _generateForHost(config, repoRoot);
    if (!ok) {
      exitCode = 1;
      return;
    }
  }
}

List<String> _resolveTargets(List<String> args) {
  final List<String> ordered = <String>[];
  void add(String target) {
    if (!_hostConfigs.containsKey(target)) return;
    if (!ordered.contains(target)) {
      ordered.add(target);
    }
  }

  if (args.isEmpty) {
    return <String>['devtools'];
  }
  for (final arg in args) {
    if (arg == '--all' || arg == 'all') {
      for (final key in _hostConfigs.keys) {
        add(key);
      }
      continue;
    }
    if (arg.startsWith('--host=')) {
      final value = arg.substring('--host='.length);
      if (value == 'all') {
        for (final key in _hostConfigs.keys) {
          add(key);
        }
      } else if (value.isNotEmpty) {
        add(value);
      }
      continue;
    }
    add(arg);
  }
  return ordered.isEmpty ? <String>['devtools'] : ordered;
}

Future<bool> _generateForHost(HostConfig config, String repoRoot) async {
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: constant_identifier_names')
    ..writeln("const String buildChannel = '${config.channel}';");

  for (final entry in config.packageFields.entries) {
    final packageDir = await _resolvePackageDir(repoRoot, entry.key);
    if (packageDir == null) {
      stderr.writeln(
        'Missing package "${entry.key}" in local repo or sibling private/oss repos.',
      );
      return false;
    }
    final pubspec = File(p.join(packageDir, 'pubspec.yaml'));
    if (!await pubspec.exists()) {
      stderr.writeln('Missing pubspec: ${pubspec.path}');
      return false;
    }
    final content = await pubspec.readAsString();
    final version = _extractVersion(content);
    if (version == null) {
      stderr.writeln('Failed to read version from ${pubspec.path}');
      return false;
    }
    buffer.writeln('const String ${entry.value} = "$version";');
  }

  final String? outputPackageDir = await _resolvePackageDir(
    repoRoot,
    config.outputPackage,
  );
  if (outputPackageDir == null) {
    stderr.writeln(
      'Missing output package "${config.outputPackage}" in local repo or sibling private/oss repos.',
    );
    return false;
  }

  final String outPath = p.join(outputPackageDir, config.outputRelativePath);
  final outDir = Directory(p.dirname(outPath));
  await outDir.create(recursive: true);
  final outFile = File(outPath);
  await outFile.writeAsString(buffer.toString());
  stdout.writeln('Wrote ${outFile.path}');
  return true;
}

String? _extractVersion(String pubspecContent) {
  for (final line in LineSplitter.split(pubspecContent)) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      return trimmed.substring('version:'.length).trim();
    }
  }
  return null;
}

Future<String?> _resolvePackageDir(String repoRoot, String packageName) async {
  final List<String> candidates = <String>[
    p.join(repoRoot, 'packages', packageName),
    p.normalize(p.join(repoRoot, '..', 'oss', 'packages', packageName)),
    p.normalize(p.join(repoRoot, '..', 'private', 'packages', packageName)),
  ];
  final Set<String> seen = <String>{};
  for (final candidate in candidates) {
    if (!seen.add(candidate)) continue;
    final dir = Directory(candidate);
    if (await dir.exists()) {
      return dir.path;
    }
  }
  return null;
}

class HostConfig {
  const HostConfig({
    required this.channel,
    required this.outputPackage,
    required this.outputRelativePath,
    required this.packageFields,
  });

  final String channel;
  final String outputPackage;
  final String outputRelativePath;
  final Map<String, String> packageFields;
}
