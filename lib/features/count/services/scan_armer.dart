import 'dart:async';

import 'package:flutter/foundation.dart';

enum ScanArmState { idle, armed }

class ScanArmer extends ValueNotifier<ScanArmState> {
  ScanArmer({
    this.onArm,
    this.onDisarm,
    this.timeout = const Duration(seconds: 5),
  }) : super(ScanArmState.idle);

  final Future<void> Function()? onArm;
  final Future<void> Function()? onDisarm;
  final Duration timeout;

  Timer? _timer;

  bool get isArmed => value == ScanArmState.armed;

  Future<void> arm() async {
    if (isArmed) return;
    value = ScanArmState.armed;
    _timer?.cancel();
    _timer = Timer(timeout, () => unawaited(disarm()));
    await onArm?.call();
  }

  Future<bool> accept() async {
    if (!isArmed) return false;
    await disarm();
    return true;
  }

  Future<void> disarm() async {
    _timer?.cancel();
    _timer = null;
    if (value == ScanArmState.idle) return;
    value = ScanArmState.idle;
    await onDisarm?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
