import 'package:flutter/material.dart';

class Tokens {
  const Tokens._();

  static const Color paper = Color(0xFFFFFFFF);
  static const Color paper2 = Color(0xFFE6EDE8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF4F8F5);

  static const Color ink = Color(0xFF17241D);
  static const Color ink2 = Color(0xFF4C5C53);
  static const Color ink3 = Color(0xFF75867C);

  static const Color line = Color(0xFFE0E8E2);
  static const Color lineStrong = Color(0xFFC5D3CA);

  static const Color green = Color(0xFF1E7A4C);
  static const Color greenDeep = Color(0xFF16603A);
  static const Color confirm = Color(0xFF2E6B4E);
  static const Color red = Color(0xFFB23A2E);
  static const Color gold = Color(0xFFB0823A);

  static Color get greenSoft => green.withValues(alpha: 0.10);
  static Color get confirmSoft => confirm.withValues(alpha: 0.12);
  static Color get redSoft => red.withValues(alpha: 0.12);
  static Color get goldSoft => gold.withValues(alpha: 0.14);

  static const String displayFont = 'Fraunces';
  static const String uiFont = 'Hanken Grotesk';

  static const double radiusCard = 14;
  static const double radiusControl = 10;
  static const double radiusKey = 8;
  static const double tapTarget = 48;
}
