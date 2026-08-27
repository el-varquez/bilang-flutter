import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/app_button.dart';
import '../../../components/empty_state.dart';
import '../../../services/feedback_service.dart';
import '../../../services/local_store.dart';
import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../services/scanner_service.dart';

class CountScreen extends StatefulWidget {
  const CountScreen({
    super.key,
    required this.storage,
    this.cameraEnabled = true,
  });

  final LocalStore storage;
  final bool cameraEnabled;

  @override
  State<CountScreen> createState() => _CountScreenState();
}

class _CountScreenState extends State<CountScreen> with WidgetsBindingObserver {
  final TextEditingController _entry = TextEditingController();
  final FocusNode _entryFocus = FocusNode();

  ScannerService? _scanner;
  StreamSubscription<String>? _subscription;
  late final FeedbackService _feedback = FeedbackService(widget.storage);
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    if (!widget.cameraEnabled) return;
    WidgetsBinding.instance.addObserver(this);
    final scanner = ScannerService();
    _scanner = scanner;
    _subscription = scanner.scans.listen(_record);
  }

  bool get _previewIsMounted =>
      context.read<CountCubit>().state.active != null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final scanner = _scanner;
    if (scanner == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _subscription ??= scanner.scans.listen(_record);
        if (_previewIsMounted) unawaited(scanner.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(scanner.stop());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    unawaited(_scanner?.dispose());
    _entry.dispose();
    _entryFocus.dispose();
    super.dispose();
  }

  int get _units {
    final batch = widget.storage.batchSize;
    return batch > 1 ? batch : 1;
  }

  Future<void> _record(String barcode) async {
    final value = barcode.trim();
    if (value.isEmpty) return;
    await context.read<CountCubit>().recordScan(value, units: _units);
    await _feedback.scanned();
  }

  Future<void> _submitTyped(String raw) async {
    _entry.clear();
    _entryFocus.requestFocus();
    await _record(raw);
  }

  Future<void> _startCount() async {
    await context.read<CountCubit>().startCount(
      'Stock count',
      at: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountCubit, CountState>(
      builder: (context, state) {
        final session = state.active;
        if (session == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  art: '| || ||| |',
                  title: 'No count open',
                  message: 'Start a count, then scan or type barcodes.',
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'START A COUNT',
                  expanded: true,
                  onPressed: _startCount,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.cameraEnabled) SizedBox(height: 220, child: _camera()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _entry,
                focusNode: _entryFocus,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: _submitTyped,
                style: AppText.mono,
                decoration: const InputDecoration(
                  hintText: 'Scan, or type a barcode',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${session.rows.length} items', style: AppText.caption),
                  Text('${session.units} units', style: AppText.counter),
                ],
              ),
            ),
            Expanded(
              child: session.rows.isEmpty
                  ? const EmptyState(
                      art: '| || ||| |',
                      title: 'Nothing counted yet',
                      message: 'Point the camera at a barcode, or type one.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: session.rows.length,
                      itemBuilder: (context, index) {
                        final row = session.rows[session.rows.length - 1 - index];
                        return ListTile(
                          title: Text(row.barcode, style: AppText.mono),
                          subtitle: Text(row.name ?? 'no name', style: AppText.caption),
                          trailing: Text('${row.qty}', style: AppText.counter),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _camera() {
    final scanner = _scanner;
    if (scanner == null) return const SizedBox.shrink();
    final error = _cameraError;
    if (error != null) {
      return ColoredBox(
        color: Tokens.surface2,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error, style: AppText.caption, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return scanner.preview(
      onError: (context, message) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _cameraError = message);
        });
        return ColoredBox(
          color: Tokens.surface2,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message, style: AppText.caption, textAlign: TextAlign.center),
            ),
          ),
        );
      },
    );
  }
}
