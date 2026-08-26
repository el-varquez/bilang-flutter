import 'package:flutter/material.dart';

import 'tokens.dart';

class AppText {
  const AppText._();

  static const List<FontVariation> _display = [FontVariation('opsz', 48)];

  static const TextStyle screenTitle = TextStyle(
    fontFamily: Tokens.displayFont,
    fontVariations: _display,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Tokens.ink,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: Tokens.displayFont,
    fontVariations: _display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Tokens.ink,
  );

  static const TextStyle counter = TextStyle(
    fontFamily: Tokens.displayFont,
    fontVariations: _display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Tokens.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle body = TextStyle(
    fontFamily: Tokens.uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Tokens.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: Tokens.uiFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Tokens.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: Tokens.uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Tokens.ink2,
  );

  static const TextStyle label = TextStyle(
    fontFamily: Tokens.uiFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Tokens.ink3,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: Tokens.uiFont,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Tokens.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
