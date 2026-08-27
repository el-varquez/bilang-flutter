import 'package:flutter/material.dart';

import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../services/scan_armer.dart';

class Viewfinder extends StatefulWidget {
  const Viewfinder({super.key, required this.state, this.preview});

  final ScanArmState state;
  final Widget? preview;

  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.state == ScanArmState.armed) _sweep.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(Viewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == ScanArmState.armed && !_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    } else if (widget.state == ScanArmState.idle && _sweep.isAnimating) {
      _sweep.stop();
      _sweep.value = 0;
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final armed = widget.state == ScanArmState.armed;
    final preview = widget.preview;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.radiusCard),
      child: ColoredBox(
        color: Tokens.ink,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?preview,
            if (preview != null && !armed)
              ColoredBox(color: Tokens.ink.withValues(alpha: 0.45)),
            _Corners(armed: armed),
            if (armed)
              AnimatedBuilder(
                animation: _sweep,
                builder: (context, child) => Align(
                  alignment: Alignment(0, (_sweep.value * 2) - 1),
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 34),
                    decoration: BoxDecoration(
                      color: Tokens.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  armed ? 'SCANNING…' : 'PRESS SCAN TO READ',
                  style: AppText.label.copyWith(
                    color: Tokens.paper.withValues(alpha: armed ? 0.55 : 0.82),
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

class _Corners extends StatelessWidget {
  const _Corners({required this.armed});

  final bool armed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 26),
      child: CustomPaint(painter: _CornerPainter(armed: armed)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.armed});

  final bool armed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Tokens.paper.withValues(alpha: armed ? 0.85 : 0.32)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const arm = 24.0;
    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin.translate(arm * dx, 0), paint);
      canvas.drawLine(origin, origin.translate(0, arm * dy), paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.armed != armed;
}
