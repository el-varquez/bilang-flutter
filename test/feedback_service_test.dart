import 'dart:io';

import 'package:bilang/services/feedback_service.dart';
import 'package:bilang/services/local_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late LocalStore storage;
  late List<MethodCall> calls;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('the defaults vibrate and stay silent', () async {
    await FeedbackService(storage).scanned();

    expect(calls.map((c) => c.method), contains('HapticFeedback.vibrate'));
    expect(calls.map((c) => c.method), isNot(contains('SystemSound.play')));
  });

  test('turning vibrate off stops the haptic', () async {
    await storage.setVibrate(false);
    await FeedbackService(storage).scanned();

    expect(calls.map((c) => c.method), isNot(contains('HapticFeedback.vibrate')));
  });

  test('turning beep on plays a sound', () async {
    await storage.setBeep(true);
    await FeedbackService(storage).scanned();

    expect(calls.map((c) => c.method), contains('SystemSound.play'));
  });
}
