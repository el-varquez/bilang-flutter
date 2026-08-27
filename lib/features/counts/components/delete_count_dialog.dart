import 'package:flutter/material.dart';

import '../../../components/app_button.dart';
import '../../../components/app_dialog.dart';
import '../../../format.dart';
import '../../../theme/app_text.dart';
import '../../../types/count_summary.dart';

Future<bool> confirmDeleteCount(
  BuildContext context,
  CountSummary summary,
) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    dialog: _DeleteCountPrompt(summary: summary),
  );
  return confirmed ?? false;
}

class _DeleteCountPrompt extends StatelessWidget {
  const _DeleteCountPrompt({required this.summary});

  final CountSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Delete count',
      subtitle: 'Are you sure to permanently delete this count?',
      actions: [
        AppButton(
          label: 'CANCEL',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: 'DELETE',
          variant: AppButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(summary.name, style: AppText.bodyStrong),
          const SizedBox(height: 4),
          Text(
            countMeta(summary.startedAt, summary.itemCount, summary.unitCount),
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
