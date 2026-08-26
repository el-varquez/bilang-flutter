import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/tokens.dart';

class CountScreen extends StatelessWidget {
  const CountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountCubit, CountState>(
      builder: (context, state) {
        final session = state.active;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bilang',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: Tokens.displayFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session == null
                    ? 'No count open'
                    : '${session.name} · ${session.rows.length} items · ${session.units} units',
                style: const TextStyle(color: Tokens.ink2),
              ),
            ],
          ),
        );
      },
    );
  }
}
