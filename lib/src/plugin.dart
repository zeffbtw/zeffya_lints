import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

import 'linter.dart';

class ZeffyaLintsPlugin extends ServerPlugin {
  ZeffyaLintsPlugin()
      : super(resourceProvider: PhysicalResourceProvider.INSTANCE);

  @override
  String get contactInfo => 'https://github.com/zeffbtw/zeffya_lints';

  @override
  List<String> get fileGlobsToAnalyze => ['**/*.dart'];

  @override
  String get name => 'zeffya_lints';

  @override
  String get version => '1.1.0';

  late ZeffyaLinter _linter;
  AnalysisContextCollection? _contextCollection;

  @override
  Future<void> afterNewContextCollection({
    required AnalysisContextCollection contextCollection,
  }) async {
    _linter = ZeffyaLinter();
    _contextCollection = contextCollection;

    for (final context in contextCollection.contexts) {
      for (final path in context.contextRoot.analyzedFiles()) {
        if (path.endsWith('.dart')) {
          await _analyzeFile(context, path);
        }
      }
    }
  }

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    await _analyzeFile(analysisContext, path);
  }

  Future<void> _analyzeFile(AnalysisContext context, String path) async {
    final result = await context.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) return;

    final errors = _linter.analyze(result);

    channel.sendNotification(
      plugin.AnalysisErrorsParams(
        path,
        errors.map((e) => _toPluginError(e, path)).toList(),
      ).toNotification(),
    );
  }

  plugin.AnalysisError _toPluginError(LintError error, String path) {
    return plugin.AnalysisError(
      plugin.AnalysisErrorSeverity.INFO,
      plugin.AnalysisErrorType.LINT,
      plugin.Location(
        path,
        error.offset,
        error.length,
        error.line,
        error.column,
        endLine: error.endLine,
        endColumn: error.endColumn,
      ),
      error.message,
      error.code,
      correction: error.correction,
      hasFix: error.hasFix,
    );
  }

  @override
  Future<plugin.EditGetFixesResult> handleEditGetFixes(
    plugin.EditGetFixesParams parameters,
  ) async {
    final path = parameters.file;
    final offset = parameters.offset;

    if (_contextCollection == null) {
      return plugin.EditGetFixesResult([]);
    }

    // Find the context for this file
    AnalysisContext? context;
    for (final ctx in _contextCollection!.contexts) {
      if (ctx.contextRoot.isAnalyzed(path)) {
        context = ctx;
        break;
      }
    }

    if (context == null) {
      return plugin.EditGetFixesResult([]);
    }

    final result = await context.currentSession.getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      return plugin.EditGetFixesResult([]);
    }

    final fixes = _linter.getFixes(result, offset);

    return plugin.EditGetFixesResult(
      fixes.map((f) => _toPluginFix(f)).toList(),
    );
  }

  plugin.AnalysisErrorFixes _toPluginFix(LintFix fix) {
    return plugin.AnalysisErrorFixes(
      plugin.AnalysisError(
        plugin.AnalysisErrorSeverity.INFO,
        plugin.AnalysisErrorType.LINT,
        plugin.Location(fix.path, fix.offset, fix.length, 1, 1),
        fix.message,
        fix.code,
      ),
      fixes: [
        plugin.PrioritizedSourceChange(
          fix.priority,
          plugin.SourceChange(
            fix.description,
            edits: [
              plugin.SourceFileEdit(
                fix.path,
                0,
                edits: fix.edits
                    .map((e) =>
                        plugin.SourceEdit(e.offset, e.length, e.replacement))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
