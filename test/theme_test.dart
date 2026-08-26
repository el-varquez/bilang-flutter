import 'package:bilang/shell/splash_screen.dart';
import 'package:bilang/theme/app_text.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:bilang/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the theme uses the design system families', () {
    final theme = AppTheme.build();
    expect(theme.textTheme.bodyMedium?.fontFamily, Tokens.uiFont);
    expect(Tokens.uiFont, 'Hanken Grotesk');
    expect(Tokens.displayFont, 'Fraunces');
  });

  test('display styles are Fraunces, body styles are Hanken Grotesk', () {
    expect(AppText.screenTitle.fontFamily, Tokens.displayFont);
    expect(AppText.counter.fontFamily, Tokens.displayFont);
    expect(AppText.body.fontFamily, Tokens.uiFont);
    expect(AppText.caption.fontFamily, Tokens.uiFont);
  });

  test('the scale matches the design system', () {
    expect(AppText.screenTitle.fontSize, 24);
    expect(AppText.sectionTitle.fontSize, 22);
    expect(AppText.counter.fontSize, 28);
    expect(AppText.body.fontSize, 14);
    expect(AppText.caption.fontSize, 12);
    expect(AppText.label.letterSpacing, 1.2);
    expect(AppText.label.fontWeight, FontWeight.w600);
  });

  test('display styles pin the optical size axis', () {
    expect(AppText.screenTitle.fontVariations, isNotEmpty);
    expect(AppText.body.fontVariations, anyOf(isNull, isEmpty));
  });

  testWidgets('the splash names the app and its listing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('Bilang'), findsOneWidget);
    expect(find.text('INVENTORY SCANNER'), findsOneWidget);
  });

  testWidgets('the splash bar fills across the hold', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    final fill = find.byKey(SplashScreen.barFillKey);
    expect(tester.getSize(fill).width, 0);

    await tester.pump(SplashScreen.hold ~/ 2);
    final midway = tester.getSize(fill).width;
    expect(midway, greaterThan(0));
    expect(midway, lessThan(120));

    await tester.pump(SplashScreen.hold);
    expect(tester.getSize(fill).width, 120);
  });
}
