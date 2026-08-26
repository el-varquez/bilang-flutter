import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  const AppTheme._();

  static const ColorScheme _scheme = ColorScheme.light(
    primary: Tokens.green,
    onPrimary: Tokens.paper,
    secondary: Tokens.confirm,
    onSecondary: Tokens.paper,
    surface: Tokens.surface,
    onSurface: Tokens.ink,
    error: Tokens.red,
    onError: Tokens.paper,
    outline: Tokens.lineStrong,
    outlineVariant: Tokens.line,
  );

  static ThemeData build() {
    final base = ThemeData(colorScheme: _scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Tokens.paper,
      textTheme: base.textTheme.apply(
        fontFamily: Tokens.uiFont,
        bodyColor: Tokens.ink,
        displayColor: Tokens.ink,
      ),
      dividerTheme: const DividerThemeData(
        color: Tokens.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
