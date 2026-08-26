import 'package:flutter/material.dart';

import '../../../store/count_store.dart';
import '../../../theme/tokens.dart';

class CountsScreen extends StatelessWidget {
  const CountsScreen({super.key, required this.store});

  final CountStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final sessions = store.sessions;
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
              subtitle: Text('${session.rows.length} items · ${session.units} units'),
              onTap: () => store.openCount(session.id),
            );
          },
        );
      },
    );
  }
}
