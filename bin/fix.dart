import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'package:zeffya_lints/src/linter.dart';

void main(List<String> args) async {
  final targetPath = args.isNotEmpty ? args.first : Directory.current.path;
  final absolutePath = Directory(targetPath).absolute.path;

  print('Analyzing $absolutePath...');

  final linter = ZeffyaLinter();
  int totalErrors = 0;
  int totalFixed = 0;
  const maxPasses = 10;

  for (int pass = 1; pass <= maxPasses; pass++) {
    final collection = AnalysisContextCollection(
      includedPaths: [absolutePath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    int passErrors = 0;
    int passFixed = 0;

    for (final context in collection.contexts) {
      for (final path in context.contextRoot.analyzedFiles()) {
        if (!path.endsWith('.dart')) continue;

        final result = await context.currentSession.getResolvedUnit(path);

        if (result is! ResolvedUnitResult) continue;

        final errors = linter.analyze(result);

        if (errors.isEmpty) continue;

        passErrors += errors.length;

        // Collect edits with priority from all fixes
        final allEdits = <({int priority, SourceEditData edit})>[];
        final fixedRules = <String>[];

        for (final error in errors) {
          final fixes = linter.getFixes(result, error.offset, code: error.code);

          if (fixes.isEmpty) continue;

          final fix = fixes.first;

          for (final edit in fix.edits) {
            allEdits.add((priority: fix.priority, edit: edit));
          }

          fixedRules.add(error.code);
        }

        if (allEdits.isEmpty) continue;

        // Sort by priority descending (structural fixes first),
        // then by length descending (larger edits first)
        allEdits.sort((a, b) {
          final pCmp = b.priority.compareTo(a.priority);

          if (pCmp != 0) return pCmp;

          return b.edit.length.compareTo(a.edit.length);
        });

        // Resolve overlaps: higher-priority edits win
        final safeEdits = <SourceEditData>[];

        for (final item in allEdits) {
          final e = item.edit;
          final eEnd = e.offset + e.length;
          final overlaps = safeEdits.any((s) {
            final sEnd = s.offset + s.length;
            return e.offset < sEnd && eEnd > s.offset;
          });

          if (!overlaps) safeEdits.add(e);
        }

        // Sort by offset descending for application
        safeEdits.sort((a, b) => b.offset.compareTo(a.offset));

        // Apply edits
        final file = File(path);
        var content = file.readAsStringSync();

        for (final edit in safeEdits) {
          if (edit.offset + edit.length > content.length) continue;

          content = content.replaceRange(
            edit.offset,
            edit.offset + edit.length,
            edit.replacement,
          );
        }

        file.writeAsStringSync(content);
        passFixed += fixedRules.toSet().length;

        final rules = fixedRules.toSet().join(', ');
        print('  [$pass] FIXED: $path [$rules]');
      }
    }

    if (pass == 1) totalErrors = passErrors;

    totalFixed += passFixed;

    if (passFixed == 0) break;

    if (pass < maxPasses) {
      print('  Pass $pass done, re-analyzing...');
    }
  }

  if (totalFixed > 0) {
    print('');
    print('Running dart format...');
    final formatResult = Process.runSync('dart', ['format', absolutePath]);

    if (formatResult.exitCode == 0) {
      print('Formatted successfully.');
    } else {
      print('Format failed: ${formatResult.stderr}');
    }
  }

  print('');
  print('Found $totalErrors issues, fixed $totalFixed.');
}
