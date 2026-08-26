import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../store/count_cubit.dart';
import '../../../store/count_state.dart';
import '../../../theme/tokens.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountCubit, CountState>(
      builder: (context, state) {
        final session = state.active;
        return Center(
          child: Text(
            session == null
                ? 'Nothing to export yet'
                : '${session.name} · ${session.rows.length} items',
            style: const TextStyle(color: Tokens.ink2),
          ),
        );
      },
    );
  }
}
