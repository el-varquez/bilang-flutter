import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/app_button.dart';
import '../../../components/app_dialog.dart';
import '../../../theme/tokens.dart';

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

Future<String?> askLiveUrl(
  BuildContext context,
  String current, {
  required Future<bool> Function(String url) probe,
}) {
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
      probe: probe,
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
    this.probe,
  });

  final String title;
  final String subtitle;
  final String initial;
  final String helperText;
  final String confirmLabel;
  final bool digitsOnly;
  final String? hintText;
  final Future<bool> Function(String url)? probe;

  @override
  State<_SettingsPrompt> createState() => _SettingsPromptState();
}

class _SettingsPromptState extends State<_SettingsPrompt> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  bool _testing = false;
  bool? _reachable;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text);

  bool get _canTest => !_testing && _controller.text.trim().isNotEmpty;

  Future<void> _test() async {
    final probe = widget.probe;
    if (probe == null) return;
    setState(() {
      _testing = true;
      _reachable = null;
    });
    final reachable = await probe(_controller.text.trim());
    if (!mounted) return;
    setState(() {
      _testing = false;
      _reachable = reachable;
    });
  }

  Widget _helper() {
    if (_testing) return const Text('Testing…');
    final reachable = _reachable;
    if (reachable == null) return Text(widget.helperText, maxLines: 2);
    return reachable
        ? const Text(
            'Connected — the endpoint answered OK',
            style: TextStyle(color: Tokens.confirm),
          )
        : const Text(
            'No answer — check the address and port',
            style: TextStyle(color: Tokens.gold),
          );
  }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
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
            onChanged: widget.probe == null
                ? null
                : (_) => setState(() => _reachable = null),
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.hintText,
              helper: _helper(),
            ),
          ),
          if (widget.probe != null) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'TEST CONNECTION',
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: _canTest ? () => unawaited(_test()) : null,
            ),
          ],
        ],
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
