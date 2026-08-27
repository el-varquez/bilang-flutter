import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/app_button.dart';
import '../../../components/empty_state.dart';
import '../../../components/new_count_dialog.dart';
import '../../../components/swipe_delete_panel.dart';
import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/app_text.dart';
import '../components/count_card.dart';
import '../components/delete_count_dialog.dart';

class CountsScreen extends StatelessWidget {
  const CountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountCubit, CountState>(
      builder: (context, state) {
        final summaries = state.summaries;
        final activeId = state.active?.id;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
              child: Text('Saved Counts', style: AppText.sectionTitle),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                'One count per stocktake. Everything is saved on this phone as you scan.',
                style: AppText.caption,
              ),
            ),
            Expanded(
              child: summaries.isEmpty
                  ? const EmptyState(
                      art: '| || ||| |',
                      title: 'No counts yet',
                      message: 'Start a count and every scan lands in it.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: summaries.length,
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        return Dismissible(
                          key: ValueKey(summary.id),
                          background: const SwipeDeletePanel(
                            alignment: Alignment.centerLeft,
                            bottomSpacing: 9,
                          ),
                          secondaryBackground: const SwipeDeletePanel(
                            alignment: Alignment.centerRight,
                            bottomSpacing: 9,
                          ),
                          confirmDismiss: (_) async {
                            final cubit = context.read<CountCubit>();
                            final confirmed = await confirmDeleteCount(
                              context,
                              summary,
                            );
                            if (confirmed) await cubit.deleteCount(summary.id);
                            return false;
                          },
                          child: CountCard(
                            summary: summary,
                            active: summary.id == activeId,
                            onTap: () => context
                                .read<CountCubit>()
                                .openCount(summary.id),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: AppButton(
                label: 'Start a new count',
                expanded: true,
                onPressed: () async {
                  final cubit = context.read<CountCubit>();
                  final name = await askCountName(context);
                  if (name == null) return;
                  await cubit.startCount(name, at: DateTime.now());
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
