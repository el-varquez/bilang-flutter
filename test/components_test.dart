import 'package:bilang/components/app_button.dart';
import 'package:bilang/components/app_card.dart';
import 'package:bilang/components/barcode_mark.dart';
import 'package:bilang/components/empty_state.dart';
import 'package:bilang/components/status_pill.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) =>
    MaterialApp(theme: AppTheme.build(), home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('a primary button shows its label and fires once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(AppButton(label: 'START COUNT', onPressed: () => taps++)),
    );

    expect(find.text('START COUNT'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a button with no callback does not fire', (tester) async {
    await tester.pumpWidget(host(const AppButton(label: 'DISABLED')));

    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('every button variant renders', (tester) async {
    for (final variant in AppButtonVariant.values) {
      await tester.pumpWidget(
        host(AppButton(label: variant.name, variant: variant, onPressed: () {})),
      );
      expect(find.text(variant.name), findsOneWidget);
    }
  });

  testWidgets('the barcode mark takes the size it is given', (tester) async {
    await tester.pumpWidget(host(const BarcodeMark(width: 150, height: 30)));

    expect(tester.getSize(find.byType(BarcodeMark)), const Size(150, 30));
  });

  testWidgets('a card wraps its child', (tester) async {
    await tester.pumpWidget(host(const AppCard(child: Text('inside'))));
    expect(find.text('inside'), findsOneWidget);
  });

  testWidgets('every pill tone renders its label', (tester) async {
    for (final tone in PillTone.values) {
      await tester.pumpWidget(host(StatusPill(label: tone.name, tone: tone)));
      expect(find.text(tone.name), findsOneWidget);
    }
  });

  testWidgets('an empty state shows all three parts', (tester) async {
    await tester.pumpWidget(
      host(
        const EmptyState(
          art: '| || ||| |',
          title: 'Nothing counted yet',
          message: 'Scan a barcode to start.',
        ),
      ),
    );

    expect(find.text('| || ||| |'), findsOneWidget);
    expect(find.text('Nothing counted yet'), findsOneWidget);
    expect(find.text('Scan a barcode to start.'), findsOneWidget);
  });

  testWidgets('an empty state squeezed below its content scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 360,
          height: 90,
          child: EmptyState(
            art: '| || ||| |',
            title: 'Nothing counted yet',
            message:
                'Point the camera at a barcode, or type one below. '
                'Every scan adds +1.',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('an empty state with room to spare stays centred', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 360,
          height: 600,
          child: EmptyState(
            art: '| || ||| |',
            title: 'Nothing counted yet',
            message: 'Scan a barcode to start.',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final box = tester.getRect(find.byType(SizedBox).first);
    final title = tester.getRect(find.text('Nothing counted yet'));
    expect((title.center.dy - box.center.dy).abs(), lessThan(40));
  });
}
