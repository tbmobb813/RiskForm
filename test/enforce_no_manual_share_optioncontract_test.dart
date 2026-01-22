import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no direct OptionContract share constructions', () {
    final root = Directory('lib');
    final regexSingle = RegExp(r"type\s*:\s*'share'");
    final regexDouble = RegExp(r'type\s*:\s*"share"');
    final allowedEndsWith = <String>['lib/strategy_cockpit/strategies/leg.dart'];

    final violations = <String>[];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // skip allowed files
        final relative = entity.path.replaceFirst('${Directory.current.path}${Platform.pathSeparator}', '').replaceAll('\\', '/');
        if (allowedEndsWith.any((s) => relative.endsWith(s))) continue;

        final content = entity.readAsStringSync();
        if (regexSingle.hasMatch(content) || regexDouble.hasMatch(content)) {
          violations.add(relative);
        }
      }
    }

    if (violations.isNotEmpty) {
      fail('Found manual OptionContract share constructions in:\n${violations.join('\n')}');
    }
  });
}
