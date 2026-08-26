import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return Dialog(
      backgroundColor: Tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.sectionTitle),
            if (subtitleText != null) ...[
              const SizedBox(height: 6),
              Text(subtitleText, style: AppText.caption),
            ],
            const SizedBox(height: 16),
            child,
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in actions) ...[
                  const SizedBox(width: 8),
                  action,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required AppDialog dialog,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Tokens.overlay,
    builder: (context) => dialog,
  );
}
