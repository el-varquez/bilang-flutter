import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings', style: TextStyle(color: Tokens.ink2)),
    );
  }
}
