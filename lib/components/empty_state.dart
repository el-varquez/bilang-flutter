import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.art,
    required this.title,
    required this.message,
  });

  final String art;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              art,
              style: const TextStyle(
                fontFamily: Tokens.uiFont,
                fontSize: 22,
                letterSpacing: 6,
                color: Tokens.ink3,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppText.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
