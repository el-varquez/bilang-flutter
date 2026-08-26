import 'package:flutter/material.dart';

import '../../../store/count_store.dart';
import '../../../theme/tokens.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key, required this.store});

  final CountStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final session = store.active;
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
