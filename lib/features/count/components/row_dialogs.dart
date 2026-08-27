import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/app_button.dart';
import '../../../components/app_dialog.dart';
import '../../../types/scan_row.dart';

Future<int?> askQuantity(BuildContext context, ScanRow row) async {
  final typed = await showAppDialog<String>(
    context: context,
    dialog: _RowPrompt(
      title: 'Quantity',
      subtitle: row.name ?? row.barcode,
      initial: '${row.qty}',
      helperText: '0 removes the row',
      confirmLabel: 'SET',
      digitsOnly: true,
    ),
  );
  if (typed == null) return null;
  return int.tryParse(typed.trim());
}

Future<String?> askName(BuildContext context, ScanRow row) {
  return showAppDialog<String>(
    context: context,
    dialog: _RowPrompt(
      title: 'Name this item',
      subtitle: row.barcode,
      initial: row.name ?? '',
      helperText: 'Optional — the barcode is enough',
      confirmLabel: 'SAVE',
      digitsOnly: false,
    ),
  );
}

class _RowPrompt extends StatefulWidget {
  const _RowPrompt({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.helperText,
    required this.confirmLabel,
    required this.digitsOnly,
  });

  final String title;
  final String subtitle;
  final String initial;
  final String helperText;
  final String confirmLabel;
  final bool digitsOnly;

  @override
  State<_RowPrompt> createState() => _RowPromptState();
}

class _RowPromptState extends State<_RowPrompt> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      subtitle: widget.subtitle,
      actions: [
        AppButton(
          label: 'CANCEL',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(label: widget.confirmLabel, onPressed: _confirm),
      ],
      child: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.digitsOnly ? TextInputType.number : null,
        inputFormatters: widget.digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        textCapitalization: widget.digitsOnly
            ? TextCapitalization.none
            : TextCapitalization.sentences,
        onSubmitted: (_) => _confirm(),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          helperText: widget.helperText,
        ),
      ),
    );
  }
}
