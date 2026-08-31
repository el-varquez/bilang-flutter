import 'dart:async';
import 'dart:io';

import 'package:bilang/components/app_button.dart';
import 'package:bilang/features/settings/screens/settings_screen.dart';
import 'package:bilang/services/live_client.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/store/settings_cubit.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:bilang/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

class ProbeLive extends LiveClient {
  ProbeLive(super.storage);

  final List<String> probed = [];
  bool answer = true;
  Completer<bool>? gate;

  @override
  Future<bool> probe(String url) async {
    probed.add(url);
    final held = gate;
    if (held != null) return held.future;
    return answer;
  }
}

Future<void> settleThroughStorage(
  WidgetTester tester,
  bool Function() settled,
) async {
  var drained = 0;
  for (var turn = 0; turn < 60; turn++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (settled()) drained++;
    if (drained > 3) return;
  }
}

void main() {
  late Directory dir;
  late LocalStore storage;
  late SettingsCubit settings;
  late CountCubit counts;
  late ProbeLive live;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    await storage.hydrate();
    settings = SettingsCubit(storage)..hydrate();
    counts = CountCubit(storage);
    await counts.hydrate();
    live = ProbeLive(storage);
  });

  tearDown(() async {
    live.dispose();
    await settings.close();
    await counts.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Widget host() => MaterialApp(
    theme: AppTheme.build(),
    home: MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: settings),
        BlocProvider<CountCubit>.value(value: counts),
      ],
      child: Scaffold(body: SettingsScreen(live: live)),
    ),
  );

  Future<void> tapLive(WidgetTester tester, Finder target) async {
    await tester.runAsync(() => tester.tap(target));
    await tester.pump();
  }

  testWidgets('it lists the four settings with their help text', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.text('Small on purpose. Scanning behavior only.'),
      findsOneWidget,
    );
    expect(find.text('Vibrate on scan'), findsOneWidget);
    expect(
      find.text('A short buzz confirms the count without looking.'),
      findsOneWidget,
    );
    expect(find.text('Beep on scan'), findsOneWidget);
    expect(find.text('The classic terminal chirp.'), findsOneWidget);
    expect(find.text('Batch scan'), findsOneWidget);
    expect(
      find.text(
        'Off — every scan adds 1. On: the app asks how many units one scan adds.',
      ),
      findsOneWidget,
    );
    expect(find.text('Live connection'), findsOneWidget);
    expect(
      find.text(
        'Off — scans stay on this phone. On: every scan POSTs to your '
        'system’s endpoint the moment it reads.',
      ),
      findsOneWidget,
    );
    expect(find.text('Delete all counts on this phone'), findsOneWidget);
  });

  testWidgets('vibrate toggles straight off, no prompt', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Vibrate on scan'));
    await settleThroughStorage(tester, () => !settings.state.vibrate);

    expect(settings.state.vibrate, isFalse);
    expect(storage.vibrate, isFalse);
  });

  testWidgets('beep toggles straight on, no prompt', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Beep on scan'));
    await settleThroughStorage(tester, () => settings.state.beep);

    expect(settings.state.beep, isTrue);
    expect(storage.beep, isTrue);
  });

  testWidgets('turning batch scan on asks how many', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Batch scan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '24');
    await tapLive(tester, find.text('SET'));
    await settleThroughStorage(tester, () => settings.state.batchSize == 24);

    expect(settings.state.batchSize, 24);
    expect(storage.batchSize, 24);
    expect(
      find.text('On — one scan adds 24 units. Tap to turn off.'),
      findsOneWidget,
    );
  });

  testWidgets('a batch below two is refused', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Batch scan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '1');
    await tapLive(tester, find.text('SET'));
    await tester.pumpAndSettle();

    expect(settings.state.batchOn, isFalse);
    expect(
      find.text('Enter 2 or more — a normal scan already adds 1'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the batch prompt leaves it off', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Batch scan'));
    await tester.pumpAndSettle();
    await tapLive(tester, find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(settings.state.batchOn, isFalse);
    expect(
      find.text(
        'Off — every scan adds 1. On: the app asks how many units one scan adds.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('turning batch scan off needs no prompt', (tester) async {
    await tester.runAsync(() => settings.setBatchSize(10));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Batch scan'));
    await settleThroughStorage(tester, () => !settings.state.batchOn);

    expect(settings.state.batchOn, isFalse);
    expect(storage.batchSize, 0);
    expect(find.text('SET'), findsNothing);
  });

  testWidgets('turning the live connection on asks for the endpoint', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your endpoint'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      'http://192.168.1.4:5103/api/scans',
    );
    await tapLive(tester, find.text('CONNECT'));
    await settleThroughStorage(tester, () => settings.state.liveOn);

    expect(settings.state.liveUrl, 'http://192.168.1.4:5103/api/scans');
    expect(
      find.text(
        'On — every scan POSTs to http://192.168.1.4:5103/api/scans. '
        'Tap to disconnect.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('turning the live connection off needs no prompt', (
    tester,
  ) async {
    await tester.runAsync(() => settings.setLiveUrl('http://example.test/s'));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await settleThroughStorage(tester, () => !settings.state.liveOn);

    expect(settings.state.liveUrl, isEmpty);
    expect(storage.liveUrl, isEmpty);
    expect(find.text('CONNECT'), findsNothing);
  });

  testWidgets('testing the endpoint reports a good connection', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'http://192.168.1.10:9000/scans',
    );
    await tester.pump();
    await tapLive(tester, find.text('TEST CONNECTION'));
    await tester.pumpAndSettle();

    expect(live.probed, ['http://192.168.1.10:9000/scans']);
    final line = tester.widget<Text>(
      find.text('Connected — the endpoint answered OK'),
    );
    expect(line.style?.color, Tokens.confirm);
    expect(settings.state.liveOn, isFalse);
  });

  testWidgets('testing the endpoint reports a dead one', (tester) async {
    live.answer = false;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'http://192.168.1.10:9000/scans',
    );
    await tester.pump();
    await tapLive(tester, find.text('TEST CONNECTION'));
    await tester.pumpAndSettle();

    final line = tester.widget<Text>(
      find.text('No answer — check the address and port'),
    );
    expect(line.style?.color, Tokens.gold);
  });

  testWidgets('the test button waits for an endpoint', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await tester.pumpAndSettle();

    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'TEST CONNECTION'),
    );
    expect(button.onPressed, isNull);
    expect(live.probed, isEmpty);
  });

  testWidgets('a running test holds the button and says so', (tester) async {
    live.gate = Completer<bool>();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'http://192.168.1.10:9000/scans',
    );
    await tester.pump();
    await tapLive(tester, find.text('TEST CONNECTION'));

    expect(find.text('Testing…'), findsOneWidget);
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'TEST CONNECTION'),
    );
    expect(button.onPressed, isNull);

    live.gate!.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Connected — the endpoint answered OK'), findsOneWidget);
  });

  testWidgets('editing the endpoint clears the last test result', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Live connection'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'http://192.168.1.10:9000/scans',
    );
    await tester.pump();
    await tapLive(tester, find.text('TEST CONNECTION'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'http://192.168.1.11:9000/scans',
    );
    await tester.pump();

    expect(find.text('Connected — the endpoint answered OK'), findsNothing);
    expect(
      find.text('Nothing leaves the phone until you connect'),
      findsOneWidget,
    );
  });

  testWidgets('deleting everything asks first and then empties storage', (
    tester,
  ) async {
    await tester.runAsync(
      () => counts.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Delete all counts on this phone'));
    await tester.pumpAndSettle();
    await tapLive(tester, find.text('DELETE'));
    await settleThroughStorage(tester, () => counts.state.summaries.isEmpty);

    expect(storage.summaries(), isEmpty);
    expect(counts.state.summaries, isEmpty);
    expect(counts.state.active, isNull);
  });

  testWidgets('cancelling the wipe keeps the counts', (tester) async {
    await tester.runAsync(
      () => counts.startCount('Bodega count', at: DateTime(2026, 8, 27)),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Delete all counts on this phone'));
    await tester.pumpAndSettle();
    await tapLive(tester, find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(storage.summaries(), isNotEmpty);
    expect(counts.state.active, isNotNull);
  });
}
