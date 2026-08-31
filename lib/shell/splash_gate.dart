import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/file_delivery.dart';
import '../services/live_client.dart';
import '../services/local_store.dart';
import '../store/count_cubit.dart';
import '../store/settings_cubit.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.store,
    this.cameraEnabled = true,
  });

  final LocalStore store;
  final bool cameraEnabled;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  CountCubit? _counts;
  SettingsCubit? _settings;
  late final LiveClient _live = LiveClient(widget.store);

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
    final settings = SettingsCubit(widget.store)..hydrate();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < SplashScreen.hold) {
      await Future<void>.delayed(SplashScreen.hold - elapsed);
    }
    if (!mounted) {
      await counts.close();
      await settings.close();
      return;
    }
    setState(() {
      _counts = counts;
      _settings = settings;
    });
  }

  @override
  void dispose() {
    _live.dispose();
    _counts?.close();
    _settings?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final settings = _settings;
    if (counts == null || settings == null) return const SplashScreen();
    return MultiBlocProvider(
      providers: [
        BlocProvider<CountCubit>.value(value: counts),
        BlocProvider<SettingsCubit>.value(value: settings),
      ],
      child: AppShell(
        storage: widget.store,
        delivery: const PlatformFileDelivery(),
        live: _live,
        cameraEnabled: widget.cameraEnabled,
      ),
    );
  }
}
