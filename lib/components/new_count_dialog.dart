import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_dialog.dart';

Future<String?> askCountName(BuildContext context) async {
  final result = await showAppDialog<String>(
    context: context,
    dialog: const _NewCountPrompt(),
  );
  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

class _NewCountPrompt extends StatefulWidget {
  const _NewCountPrompt();

  @override
  State<_NewCountPrompt> createState() => _NewCountPromptState();
}

class _NewCountPromptState extends State<_NewCountPrompt> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Start a new count',
      subtitle: 'The count you are on now closes when this one starts.',
      actions: [
        AppButton(
          label: 'CANCEL',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'START',
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
      child: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Count name',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
