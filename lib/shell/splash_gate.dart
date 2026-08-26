import 'package:flutter/material.dart';

import '../services/local_store.dart';
import '../store/count_store.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.store});

  final LocalStore store;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const Duration _minimumSplash = Duration(milliseconds: 600);

  CountStore? _counts;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final started = DateTime.now();
    await widget.store.hydrate();
    final counts = CountStore(widget.store);
    await counts.hydrate();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minimumSplash) {
      await Future<void>.delayed(_minimumSplash - elapsed);
    }
    if (!mounted) return;
    setState(() => _counts = counts);
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    if (counts == null) return const SplashScreen();
    return AppShell(store: counts);
  }
}
