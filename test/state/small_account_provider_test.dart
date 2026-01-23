import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/state/small_account_provider.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test_hive');
  });

  tearDownAll(() async {
    final dir = Directory('./test_hive');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('validate rejects invalid settings', () {
    final notifier = SmallAccountNotifier();
    final bad = SmallAccountSettings(enabled: true, startingCapital: 0.0, maxAllocationPct: 1.5, minTradeSize: 0.0, maxOpenPositions: 0);
    final errs = notifier.validate(bad);
    expect(errs.isNotEmpty, true);
    expect(errs.containsKey('startingCapital'), true);
    expect(errs.containsKey('maxAllocationPct'), true);
    expect(errs.containsKey('minTradeSize'), true);
    expect(errs.containsKey('maxOpenPositions'), true);
  });

  test('save returns true for valid settings', () async {
    final notifier = SmallAccountNotifier();
    notifier.updateStartingCapital(5000);
    notifier.updateMaxAllocationPct(0.2);
    notifier.updateMinTradeSize(50);
    notifier.updateMaxOpenPositions(2);
    final ok = await notifier.save();
    expect(ok, true);
  });
}
