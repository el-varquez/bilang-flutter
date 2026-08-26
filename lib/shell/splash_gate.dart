import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_store.dart';
import '../store/count_cubit.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.store});

  final LocalStore store;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  CountCubit? _counts;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final started = DateTime.now();
    await widget.store.hydrate();
    final counts = CountCubit(widget.store);
    await counts.hydrate();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < SplashScreen.hold) {
      await Future<void>.delayed(SplashScreen.hold - elapsed);
    }
    if (!mounted) {
      await counts.close();
      return;
    }
    setState(() => _counts = counts);
  }

  @override
  void dispose() {
    _counts?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    if (counts == null) return const SplashScreen();
    return BlocProvider<CountCubit>.value(
      value: counts,
      child: const AppShell(),
    );
  }
}
