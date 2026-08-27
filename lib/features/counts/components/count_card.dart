import 'package:flutter/material.dart';

import '../../../components/status_pill.dart';
import '../../../format.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../types/count_summary.dart';

class CountCard extends StatelessWidget {
  const CountCard({
    super.key,
    required this.summary,
    required this.active,
    required this.onTap,
  });

  final CountSummary summary;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = summary.itemCount;
    final units = summary.unitCount;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
          boxShadow: const [
            BoxShadow(
              color: Tokens.shadowSm,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? Tokens.greenSoft : Tokens.surface,
              border: Border.all(color: Tokens.line),
              borderRadius: BorderRadius.circular(Tokens.radiusControl),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              summary.name,
                              style: AppText.bodyStrong.copyWith(fontSize: 14.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            label: summary.open ? '● Open' : 'Done',
                            tone: summary.open
                                ? PillTone.open
                                : PillTone.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        countMeta(summary.startedAt, items, units),
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: ColoredBox(
                    color: active ? Tokens.green : Tokens.line,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
