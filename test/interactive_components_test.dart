import 'package:bilang/components/app_button.dart';
import 'package:bilang/components/app_dialog.dart';
import 'package:bilang/components/app_switch.dart';
import 'package:bilang/components/app_toast.dart';
import 'package:bilang/components/setting_row.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) =>
    MaterialApp(theme: AppTheme.build(), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('a switch reports the flipped value', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      host(AppSwitch(value: false, onChanged: (v) => reported = v)),
    );

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(reported, isTrue);
  });

  testWidgets('a switch carries its semantics', (tester) async {
    await tester.pumpWidget(host(AppSwitch(value: true, onChanged: (_) {})));

    final flags = tester.getSemantics(find.byType(AppSwitch)).flagsCollection;
    expect(flags.isToggled.toBoolOrNull(), isNotNull);
    expect(flags.isToggled.toBoolOrNull(), isTrue);
  });

  testWidgets('a setting row shows its name and help, and toggles', (tester) async {
    bool? reported;
    await tester.pumpWidget(
      host(
        SettingRow(
          name: 'Vibrate on scan',
          help: 'A short buzz confirms the count.',
          value: false,
          onChanged: (v) => reported = v,
        ),
      ),
    );

    expect(find.text('Vibrate on scan'), findsOneWidget);
    expect(find.text('A short buzz confirms the count.'), findsOneWidget);

    await tester.tap(find.byType(SettingRow));
    await tester.pumpAndSettle();
    expect(reported, isTrue);
  });

  testWidgets('a toast appears then disappears', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'SHOW',
            onPressed: () => showAppToast(context, 'Last scan undone'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(find.text('Last scan undone'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Last scan undone'), findsNothing);
  });

  testWidgets('a dialog renders its title, body and actions', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => AppButton(
            label: 'OPEN',
            onPressed: () => showAppDialog<void>(
              context: context,
              dialog: AppDialog(
                title: 'Delete all counts?',
                subtitle: 'This cannot be undone.',
                actions: [
                  AppButton(
                    label: 'CANCEL',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
                child: const Text('body'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('Delete all counts?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
  });
}
