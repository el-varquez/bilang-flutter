import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/app_button.dart';
import '../../../components/app_toast.dart';
import '../../../components/empty_state.dart';
import '../../../services/feedback_service.dart';
import '../../../services/local_store.dart';
import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../types/scan_row.dart';
import '../components/count_row.dart';
import '../components/row_dialogs.dart';
import '../components/viewfinder.dart';
import '../services/scan_armer.dart';
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
  late final ScanArmer _armer = ScanArmer(onArm: _freshThrottle);
  late final FeedbackService _feedback = FeedbackService(widget.storage);
  String? _cameraError;
  String? _flashBarcode;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.cameraEnabled) return;
    WidgetsBinding.instance.addObserver(this);
    final scanner = ScannerService();
    _scanner = scanner;
    _subscription = scanner.scans.listen(_onDecoded);
    unawaited(scanner.start());
  }

  Future<void> _freshThrottle() async => _scanner?.resetThrottle();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final scanner = _scanner;
    if (scanner == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _subscription ??= scanner.scans.listen(_onDecoded);
        unawaited(scanner.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_armer.disarm());
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
    _flashTimer?.cancel();
    unawaited(_subscription?.cancel());
    _armer.dispose();
    unawaited(_scanner?.dispose());
    _entry.dispose();
    _entryFocus.dispose();
    super.dispose();
  }

  int get _units {
    final batch = widget.storage.batchSize;
    return batch > 1 ? batch : 1;
  }

  Future<void> _onDecoded(String barcode) async {
    if (!await _armer.accept()) return;
    await _record(barcode);
  }

  Future<void> _record(String barcode) async {
    final value = barcode.trim();
    if (value.isEmpty) return;
    await context.read<CountCubit>().recordScan(value, units: _units);
    await _feedback.scanned();
    if (!mounted) return;
    setState(() => _flashBarcode = value);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _flashBarcode = null);
    });
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

  Future<void> _editQuantity(ScanRow row) async {
    final cubit = context.read<CountCubit>();
    final qty = await askQuantity(context, row);
    if (qty == null) return;
    await cubit.setQuantity(row.barcode, qty);
    if (!mounted) return;
    if (qty > 0) return;
    showAppToast(context, 'Row removed');
  }

  Future<void> _remove(ScanRow row) async {
    await context.read<CountCubit>().setQuantity(row.barcode, 0);
    if (!mounted) return;
    showAppToast(context, 'Row removed');
  }

  Future<void> _editName(ScanRow row) async {
    final cubit = context.read<CountCubit>();
    final name = await askName(context, row);
    if (name == null) return;
    await cubit.nameRow(row.barcode, name);
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

        return ValueListenableBuilder<ScanArmState>(
          valueListenable: _armer,
          builder: (context, armState, child) {
            final armed = armState == ScanArmState.armed;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: SizedBox(
                    height: 192,
                    child: Viewfinder(state: armState, preview: _preview()),
                  ),
                ),
                _wedge(),
                _counters(session.rows.length, session.units),
                Expanded(child: _rows(session.rows)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: AppButton(
                    label: 'SCAN',
                    expanded: true,
                    background: armed ? Tokens.greenDeep : null,
                    onPressed: widget.cameraEnabled ? _armer.arm : null,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _wedge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
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
                hintText: 'Type a barcode — hardware scanners land here',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          AppButton(
            label: 'ADD',
            onPressed: () => unawaited(_submitTyped(_entry.text)),
          ),
        ],
      ),
    );
  }

  Widget _counters(int items, int units) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        spacing: 8,
        children: [
          Expanded(child: _counterTile('Items', items, Alignment.centerLeft)),
          Expanded(
            child: _counterTile('Units counted', units, Alignment.centerRight),
          ),
        ],
      ),
    );
  }

  Widget _counterTile(String label, int value, Alignment alignment) {
    final start = alignment == Alignment.centerLeft;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: Tokens.surface2,
        border: Border.all(color: Tokens.line),
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: start
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(label.toUpperCase(), style: AppText.label),
          Text('$value', style: AppText.counter),
        ],
      ),
    );
  }

  Widget _rows(List<ScanRow> rows) {
    if (rows.isEmpty) {
      return const EmptyState(
        art: '| || ||| |',
        title: 'Nothing counted yet',
        message:
            'Point the camera at a barcode, or type one below. '
            'Every scan adds +1.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[rows.length - 1 - index];
        final cubit = context.read<CountCubit>();
        return Dismissible(
          key: ValueKey(row.barcode),
          background: _swipeAway(Alignment.centerLeft),
          secondaryBackground: _swipeAway(Alignment.centerRight),
          confirmDismiss: (_) async {
            await _remove(row);
            return false;
          },
          child: CountRow(
            row: row,
            flashing: row.barcode == _flashBarcode,
            onDecrement: () => unawaited(
              cubit.setQuantity(row.barcode, row.qty > 1 ? row.qty - 1 : 1),
            ),
            onIncrement: () =>
                unawaited(cubit.setQuantity(row.barcode, row.qty + 1)),
            onEditQuantity: () => unawaited(_editQuantity(row)),
            onEditName: () => unawaited(_editName(row)),
          ),
        );
      },
    );
  }

  Widget _swipeAway(Alignment alignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Tokens.red,
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
        ),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Delete',
              style: AppText.bodyStrong.copyWith(color: Tokens.paper),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _preview() {
    if (!widget.cameraEnabled) return null;
    final scanner = _scanner;
    if (scanner == null) return null;
    final error = _cameraError;
    if (error != null) return _cameraNotice(error);
    return scanner.preview(
      onError: (context, message) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _cameraError = message);
        });
        return _cameraNotice(message);
      },
    );
  }

  Widget _cameraNotice(String message) {
    return ColoredBox(
      color: Tokens.surface2,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
