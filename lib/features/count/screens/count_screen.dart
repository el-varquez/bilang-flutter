import 'package:flutter/material.dart';

import '../../../store/count_store.dart';
import '../../../theme/tokens.dart';

class CountScreen extends StatelessWidget {
  const CountScreen({super.key, required this.store});

  final CountStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final session = store.active;
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
