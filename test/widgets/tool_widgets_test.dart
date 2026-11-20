import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/widgets/tools/tool_widgets.dart';

void main() {
  testWidgets('ResultRow shows label and value without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: ResultRow(
              'A fairly long label that must wrap',
              '\$1,234,567.89 and a long value',
            ),
          ),
        ),
      ),
    );

    expect(find.text('A fairly long label that must wrap'), findsOneWidget);
    expect(find.text('\$1,234,567.89 and a long value'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultSection shows its title and rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResultSection('Totals', [ResultRow('Cash', '\$10')]),
        ),
      ),
    );

    expect(find.text('Totals'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('\$10'), findsOneWidget);
  });

  testWidgets('ToolField reports changes and picks keyboard by kind', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ToolField(
                controller: controller,
                label: 'Price',
                onChanged: changes.add,
              ),
              ToolField(
                controller: TextEditingController(),
                label: 'Days',
                kind: ToolFieldKind.integer,
              ),
              ToolField(
                controller: TextEditingController(),
                label: 'Symbol',
                kind: ToolFieldKind.text,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Price'), '12.5');
    expect(changes, ['12.5']);

    TextField field(String label) =>
        tester.widget<TextField>(find.widgetWithText(TextField, label));
    expect(
      field('Price').keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      field('Days').keyboardType,
      const TextInputType.numberWithOptions(decimal: false),
    );
    expect(field('Symbol').keyboardType, TextInputType.text);
    expect(field('Symbol').textCapitalization, TextCapitalization.characters);
    expect(field('Price').textCapitalization, TextCapitalization.none);
  });
}
