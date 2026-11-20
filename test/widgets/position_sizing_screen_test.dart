import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/account_context.dart';
import 'package:riskform/screens/position_sizing/position_sizing_screen.dart';
import 'package:riskform/state/account_context_provider.dart';

void main() {
  testWidgets('an initial buying power overrides the saved account value', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountContextProvider.overrideWith(
            (ref) async =>
                const AccountContext(accountSize: 10000, buyingPower: 8000),
          ),
        ],
        child: const MaterialApp(
          home: PositionSizingScreen(initialBuyingPower: 1500),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, '10000');
    expect(tester.widget<TextField>(fields.at(3)).controller!.text, '1500');
  });

  testWidgets('prefills account and sizes a cash-secured put', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountContextProvider.overrideWith(
            (ref) async =>
                const AccountContext(accountSize: 10000, buyingPower: 8000),
          ),
        ],
        child: const MaterialApp(home: PositionSizingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    // strike, premium, account, buying power, max capital %, max loss %.
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, '10000');
    expect(tester.widget<TextField>(fields.at(3)).controller!.text, '8000');

    await tester.enterText(fields.at(0), '20');
    await tester.enterText(fields.at(1), '0.50');
    await tester.enterText(fields.at(4), '50');
    await tester.enterText(fields.at(5), '50');
    await tester.pump();

    expect(find.text('2 contracts'), findsOneWidget);
    expect(find.text('\$2000'), findsOneWidget);
  });
}
