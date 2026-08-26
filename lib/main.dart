import 'package:flutter/material.dart';

import 'shell/app_shell.dart';
import 'store/count_store.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(BilangApp(store: CountStore()));
}

class BilangApp extends StatelessWidget {
  const BilangApp({super.key, required this.store});

  final CountStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: AppShell(store: store),
    );
  }
}
