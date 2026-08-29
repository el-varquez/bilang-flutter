import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/app_button.dart';
import '../../../components/app_toast.dart';
import '../../../components/empty_state.dart';
import '../../../services/export_service.dart';
import '../../../services/file_delivery.dart';
import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/app_text.dart';
import '../../../theme/tokens.dart';
import '../../../types/count_session.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.delivery});

  final FileDelivery delivery;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportFormat _format = ExportFormat.csv;

  String _subtitle(CountSession session) {
    final items = session.rows.length;
    final units = session.units;
    return '"${session.name}" · $items item${items == 1 ? '' : 's'} '
        '· $units unit${units == 1 ? '' : 's'}';
  }

  String _preview(CountSession session) => _format == ExportFormat.json
      ? ExportService.json(session)
      : ExportService.csv(session);

  Future<void> _share(CountSession session) async {
    final name = ExportService.fileName(session, _format);
    final outcome = await widget.delivery.share(
      fileName: name,
      bytes: ExportService.bytes(session, _format),
      mimeType: ExportService.mimeType(_format),
    );
    if (!mounted || outcome != ShareOutcome.shared) return;
    showAppToast(context, 'Shared $name');
  }

  Future<void> _save(CountSession session) async {
    final name = ExportService.fileName(session, _format);
    final saved = await widget.delivery.save(
      fileName: name,
      bytes: ExportService.bytes(session, _format),
      mimeType: ExportService.mimeType(_format),
    );
    if (!mounted) return;
    showAppToast(context, saved ? 'Saved $name' : 'Save cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountCubit, CountState>(
      builder: (context, state) {
        final session = state.active;
        if (session == null) {
          return const EmptyState(
            art: '| || ||| |',
            title: 'Nothing to export yet',
            message: 'Start a count and its file appears here.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
              child: Text('Export & share', style: AppText.sectionTitle),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(_subtitle(session), style: AppText.caption),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: IntrinsicHeight(
                child: Row(
                  spacing: 9,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final option in ExportFormat.values)
                      Expanded(
                        child: _FormatCard(
                          name: _labelOf(option),
                          note: _noteOf(option),
                          selected: option == _format,
                          onTap: () => setState(() => _format = option),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _Preview(
                  fileName: ExportService.fileName(session, _format),
                  body: _preview(session),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Share file',
                      onPressed: () => unawaited(_share(session)),
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      label: 'Download',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => unawaited(_save(session)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

String _labelOf(ExportFormat format) => switch (format) {
  ExportFormat.csv => 'CSV',
  ExportFormat.xlsx => 'Excel',
  ExportFormat.json => 'JSON',
};

String _noteOf(ExportFormat format) => switch (format) {
  ExportFormat.csv => 'Opens anywhere.',
  ExportFormat.xlsx => 'Real .xlsx file.',
  ExportFormat.json => 'For systems.',
};

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.name,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Tokens.greenSoft : Tokens.surface,
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
          border: Border.all(
            color: selected ? Tokens.green : Tokens.lineStrong,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppText.bodyStrong.copyWith(
                fontSize: 14.5,
                color: selected ? Tokens.greenDeep : Tokens.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(note, style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.fileName, required this.body});

  final String fileName;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 13),
      decoration: BoxDecoration(
        color: Tokens.surface,
        borderRadius: BorderRadius.circular(Tokens.radiusControl),
        border: Border.all(color: Tokens.line),
        boxShadow: const [
          BoxShadow(color: Tokens.shadowSm, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(fileName, style: AppText.label),
          ),
          const _DashedRule(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  body,
                  style: AppText.mono.copyWith(fontSize: 11, height: 1.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashes = (constraints.maxWidth / 7).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashes,
            (_) => const SizedBox(
              width: 4,
              height: 1,
              child: ColoredBox(color: Tokens.lineStrong),
            ),
          ),
        );
      },
    );
  }
}
