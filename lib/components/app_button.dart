import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum AppButtonVariant { primary, secondary, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool expanded;

  Color get _background => switch (variant) {
    AppButtonVariant.primary => Tokens.green,
    AppButtonVariant.destructive => Tokens.red,
    AppButtonVariant.secondary => Colors.transparent,
  };

  Color get _foreground => switch (variant) {
    AppButtonVariant.secondary => Tokens.ink2,
    _ => Tokens.paper,
  };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: _background,
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
          child: Container(
            constraints: const BoxConstraints(minHeight: Tokens.tapTarget),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radiusControl),
              border: variant == AppButtonVariant.secondary
                  ? Border.all(color: Tokens.lineStrong)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Tokens.uiFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: _foreground,
              ),
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
