import 'package:bilang/main.dart';
import 'package:bilang/store/count_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the shell renders the four tabs and opens the count screen', (
    tester,
  ) async {
    await tester.pumpWidget(BilangApp(store: CountStore()));

    expect(find.text('Count'), findsOneWidget);
    expect(find.text('Counts'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('No count open'), findsOneWidget);
  });

  testWidgets('tapping a tab switches the screen', (tester) async {
    await tester.pumpWidget(BilangApp(store: CountStore()));

    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.text('No counts yet'), findsOneWidget);
  });
}
