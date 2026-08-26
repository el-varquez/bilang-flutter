import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Tokens.paper,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '| || ||| |',
              style: TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                color: Tokens.ink3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Bilang',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFamily: Tokens.displayFont,
                fontWeight: FontWeight.w700,
                color: Tokens.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inventory Scanner',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Tokens.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
