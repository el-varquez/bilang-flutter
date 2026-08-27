import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/tokens.dart';

class SwipeDeletePanel extends StatelessWidget {
  const SwipeDeletePanel({
    super.key,
    required this.alignment,
    this.bottomSpacing = 8,
  });

  final Alignment alignment;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Tokens.red,
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
        ),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Delete',
              style: AppText.bodyStrong.copyWith(color: Tokens.paper),
            ),
          ),
        ),
      ),
    );
  }
}
