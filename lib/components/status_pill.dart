import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum PillTone { neutral, open, warn, danger }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  Color get _background => switch (tone) {
    PillTone.neutral => Tokens.surface2,
    PillTone.open => Tokens.confirmSoft,
    PillTone.warn => Tokens.goldSoft,
    PillTone.danger => Tokens.redSoft,
  };

  Color get _foreground => switch (tone) {
    PillTone.neutral => Tokens.ink2,
    PillTone.open => Tokens.confirm,
    PillTone.warn => Tokens.gold,
    PillTone.danger => Tokens.red,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Tokens.uiFont,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _foreground,
        ),
      ),
    );
  }
}
