import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class BarcodeMark extends StatelessWidget {
  const BarcodeMark({
    super.key,
    this.width = 150,
    this.height = 30,
    this.color = Tokens.ink3,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _BarcodePainter(color)),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter(this.color);

  final Color color;

  static const List<int> _modules = [
    3, 1, 1, 2, 2, 1, 1, 1, 3, 2, 1, 1, 2, 3, 1, 1,
    1, 2, 2, 1, 3, 1, 1, 2, 1, 1, 2, 2, 1, 3, 2,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    var total = 0;
    for (final run in _modules) {
      total += run;
    }
    final module = size.width / total;
    final paint = Paint()..color = color;
    var x = 0.0;
    for (var i = 0; i < _modules.length; i++) {
      final run = _modules[i] * module;
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(x, 0, run, size.height), paint);
      }
      x += run;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) => oldDelegate.color != color;
}
