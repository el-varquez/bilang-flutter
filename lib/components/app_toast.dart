import 'package:flutter/material.dart';

import '../theme/tokens.dart';

void showAppToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 24,
      right: 24,
      bottom: 96,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: Tokens.ink,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Tokens.uiFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Tokens.paper,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2800), entry.remove);
}
