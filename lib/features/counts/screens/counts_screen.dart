import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/tokens.dart';

class CountsScreen extends StatelessWidget {
  const CountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountCubit, CountState>(
      builder: (context, state) {
        final sessions = state.summaries;
        if (sessions.isEmpty) {
          return const Center(
            child: Text('No counts yet', style: TextStyle(color: Tokens.ink2)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return ListTile(
              title: Text(session.name),
              subtitle: Text(
                '${session.itemCount} items · ${session.unitCount} units',
              ),
              onTap: () => context.read<CountCubit>().openCount(session.id),
            );
          },
        );
      },
    );
  }
}
