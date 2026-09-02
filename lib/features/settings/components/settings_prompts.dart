import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/app_button.dart';
import '../../../components/app_dialog.dart';

Future<int?> askBatchSize(BuildContext context, int current) async {
  final typed = await showAppDialog<String>(
    context: context,
    dialog: _SettingsPrompt(
      title: 'Batch scan',
      subtitle: 'How many units does one scan add?',
      initial: current > 1 ? '$current' : '10',
      helperText: '2 or more — a normal scan already adds 1',
      confirmLabel: 'SET',
      digitsOnly: true,
    ),
  );
  if (typed == null) return null;
  return int.tryParse(typed.trim()) ?? 0;
}

Future<String?> askLiveUrl(BuildContext context, String current) {
  return showAppDialog<String>(
    context: context,
    dialog: _SettingsPrompt(
      title: 'Live connection',
      subtitle: 'POST endpoint — every scan is sent here as JSON',
      initial: current,
      hintText: 'Enter your endpoint',
      helperText: 'Nothing leaves the phone until you connect',
      confirmLabel: 'CONNECT',
      digitsOnly: false,
    ),
  );
}

Future<bool> confirmDeleteAll(BuildContext context) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    dialog: const _DeleteAllPrompt(),
  );
  return confirmed ?? false;
}

class _SettingsPrompt extends StatefulWidget {
  const _SettingsPrompt({
    required this.title,
    required this.subtitle,
    required this.initial,
    required this.helperText,
    required this.confirmLabel,
    required this.digitsOnly,
    this.hintText,
  });

  final String title;
  final String subtitle;
  final String initial;
  final String helperText;
  final String confirmLabel;
  final bool digitsOnly;
  final String? hintText;

  @override
  State<_SettingsPrompt> createState() => _SettingsPromptState();
}

class _SettingsPromptState extends State<_SettingsPrompt> {
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
        keyboardType: widget.digitsOnly
            ? TextInputType.number
            : TextInputType.url,
        inputFormatters: widget.digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: (_) => _confirm(),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: widget.hintText,
          helperText: widget.helperText,
          helperMaxLines: 2,
        ),
      ),
    );
  }
}

class _DeleteAllPrompt extends StatelessWidget {
  const _DeleteAllPrompt();

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Delete all counts',
      subtitle: 'Delete every count stored on this phone? '
          'This cannot be undone.',
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
      child: const SizedBox.shrink(),
    );
  }
}
