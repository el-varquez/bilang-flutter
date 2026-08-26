import 'package:flutter/material.dart';

import '../components/barcode_mark.dart';
import '../theme/app_text.dart';
import '../theme/tokens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Duration hold = Duration(seconds: 3);
  static const Key barFillKey = ValueKey('splashBarFill');

  static const double _barWidth = 120;
  static const double _barHeight = 3;

  static final TextStyle _name = AppText.screenTitle.copyWith(
    fontSize: 48,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Tokens.paper,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BarcodeMark(width: 150, height: 30),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bilang', style: _name),
                Text('.', style: _name.copyWith(color: Tokens.green)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'INVENTORY SCANNER',
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2.64,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: _barWidth,
              height: _barHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Tokens.line,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: hold,
                  curve: Curves.ease,
                  builder: (context, value, child) => Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      key: barFillKey,
                      width: _barWidth * value,
                      height: _barHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Tokens.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
