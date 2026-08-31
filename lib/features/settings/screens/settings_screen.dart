import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/app_button.dart';
import '../../../components/app_toast.dart';
import '../../../components/setting_row.dart';
import '../../../services/live_client.dart';
import '../../../store/count_cubit.dart';
import '../../../store/settings_cubit.dart';
import '../../../store/settings_state.dart';
import '../../../theme/app_text.dart';
import '../components/settings_prompts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.live});

  final LiveClient live;

  static String batchHelp(SettingsState state) => state.batchOn
      ? 'On — one scan adds ${state.batchSize} units. Tap to turn off.'
      : 'Off — every scan adds 1. On: the app asks how many units one '
            'scan adds.';

  static String liveHelp(SettingsState state) => state.liveOn
      ? 'On — every scan POSTs to ${state.liveUrl}. Tap to disconnect.'
      : 'Off — scans stay on this phone. On: every scan POSTs to your '
            'system’s endpoint the moment it reads.';

  Future<void> _toggleBatch(BuildContext context, SettingsState state) async {
    final cubit = context.read<SettingsCubit>();
    if (state.batchOn) {
      await cubit.setBatchSize(0);
      if (!context.mounted) return;
      showAppToast(context, 'Batch scan off — every scan adds 1');
      return;
    }
    final size = await askBatchSize(context, state.batchSize);
    if (size == null || !context.mounted) return;
    if (size < 2) {
      showAppToast(context, 'Enter 2 or more — a normal scan already adds 1');
      return;
    }
    await cubit.setBatchSize(size);
    if (!context.mounted) return;
    showAppToast(context, 'Batch scan on — one scan adds $size units');
  }

  Future<void> _toggleLive(BuildContext context, SettingsState state) async {
    final cubit = context.read<SettingsCubit>();
    if (state.liveOn) {
      await cubit.setLiveUrl('');
      if (!context.mounted) return;
      showAppToast(context, 'Live connection off — scans stay on this phone');
      return;
    }
    final url = await askLiveUrl(context, state.liveUrl, probe: live.probe);
    if (url == null || url.trim().isEmpty) return;
    await cubit.setLiveUrl(url);
    if (!context.mounted) return;
    showAppToast(context, 'Live — every scan now POSTs to your system');
  }

  Future<void> _deleteEverything(BuildContext context) async {
    final settings = context.read<SettingsCubit>();
    final counts = context.read<CountCubit>();
    final confirmed = await confirmDeleteAll(context);
    if (!confirmed) return;
    await settings.deleteAllCounts();
    await counts.hydrate();
    if (!context.mounted) return;
    showAppToast(context, 'All counts deleted');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
              child: Text('Settings', style: AppText.sectionTitle),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                'Small on purpose. Scanning behavior only.',
                style: AppText.caption,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                spacing: 10,
                children: [
                  SettingRow(
                    name: 'Vibrate on scan',
                    help: 'A short buzz confirms the count without looking.',
                    value: state.vibrate,
                    onChanged: (value) => unawaited(
                      context.read<SettingsCubit>().setVibrate(value),
                    ),
                  ),
                  SettingRow(
                    name: 'Beep on scan',
                    help: 'The classic terminal chirp.',
                    value: state.beep,
                    onChanged: (value) =>
                        unawaited(context.read<SettingsCubit>().setBeep(value)),
                  ),
                  SettingRow(
                    name: 'Batch scan',
                    help: batchHelp(state),
                    value: state.batchOn,
                    onChanged: (_) => unawaited(_toggleBatch(context, state)),
                  ),
                  SettingRow(
                    name: 'Live connection',
                    help: liveHelp(state),
                    value: state.liveOn,
                    onChanged: (_) => unawaited(_toggleLive(context, state)),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Delete all counts on this phone',
                    variant: AppButtonVariant.destructive,
                    expanded: true,
                    onPressed: () => unawaited(_deleteEverything(context)),
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
