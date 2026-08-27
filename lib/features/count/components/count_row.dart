import 'package:flutter/material.dart';

import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../types/scan_row.dart';

class CountRow extends StatelessWidget {
  const CountRow({
    super.key,
    required this.row,
    this.flashing = false,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEditQuantity,
    required this.onEditName,
  });

  final ScanRow row;
  final bool flashing;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEditQuantity;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final named = row.name != null && row.name!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: flashing ? Tokens.greenSoft : Tokens.surface,
            border: Border.all(color: Tokens.line),
            borderRadius: BorderRadius.circular(Tokens.radiusControl),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 12, 10),
                child: _content(named),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  color: flashing ? Tokens.green : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(bool named) {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onEditName,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.barcode, style: AppText.mono),
                Text(
                  named ? row.name! : 'tap to name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: named ? Tokens.ink2 : Tokens.ink3,
                    fontStyle: named ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          spacing: 3,
          children: [
            _StepButton(label: '−', onPressed: onDecrement),
            GestureDetector(
              onTap: onEditQuantity,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 46,
                child: Text(
                  '${row.qty}',
                  textAlign: TextAlign.center,
                  style: AppText.counter.copyWith(fontSize: 18),
                ),
              ),
            ),
            _StepButton(label: '+', onPressed: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: Tokens.surface2,
        borderRadius: BorderRadius.circular(Tokens.radiusKey),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(Tokens.radiusKey),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Tokens.lineStrong),
              borderRadius: BorderRadius.circular(Tokens.radiusKey),
            ),
            alignment: Alignment.center,
            child: Text(label, style: AppText.bodyStrong),
          ),
        ),
      ),
    );
  }
}
