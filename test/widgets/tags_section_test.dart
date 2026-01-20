import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:riskform/screens/planner/components/tags_section.dart';

void main() {
  testWidgets('TagsSection toggles tag selection and calls onChanged', (WidgetTester tester) async {
    List<String>? last;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TagsSection(
          selectedTags: [],
          onChanged: (v) => last = List.from(v),
        ),
      ),
    ));

    // Tap the 'income' chip
    await tester.tap(find.text('income'));
    await tester.pumpAndSettle();

    expect(last, isNotNull);
    expect(last, contains('income'));
  });
}
