import 'package:flutter/material.dart';

import 'services/local_store.dart';
import 'shell/splash_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  final store = await LocalStore.openForApp();
  runApp(BilangApp(store: store));
}

class BilangApp extends StatelessWidget {
  const BilangApp({super.key, required this.store});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: SplashGate(store: store),
    );
  }
}
