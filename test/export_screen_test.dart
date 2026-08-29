import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bilang/features/export/screens/export_screen.dart';
import 'package:bilang/services/file_delivery.dart';
import 'package:bilang/services/local_store.dart';
import 'package:bilang/store/count_cubit.dart';
import 'package:bilang/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

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

class FakeDelivery implements FileDelivery {
  String? sharedName;
  String? sharedMime;
  Uint8List? sharedBytes;
  String? savedName;
  String? savedMime;
  ShareOutcome outcome = ShareOutcome.shared;
  bool saveResult = true;

  @override
  Future<ShareOutcome> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    sharedName = fileName;
    sharedMime = mimeType;
    sharedBytes = bytes;
    return outcome;
  }

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    savedName = fileName;
    savedMime = mimeType;
    return saveResult;
  }
}

void main() {
  late Directory dir;
  late LocalStore storage;
  late CountCubit counts;
  late FakeDelivery delivery;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_test_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    await storage.hydrate();
    counts = CountCubit(storage);
    await counts.hydrate();
    delivery = FakeDelivery();
  });

  tearDown(() async {
    await counts.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Widget host() => MaterialApp(
    theme: AppTheme.build(),
    home: BlocProvider<CountCubit>.value(
      value: counts,
      child: Scaffold(body: ExportScreen(delivery: delivery)),
    ),
  );

  Future<void> tapLive(WidgetTester tester, Finder target) async {
    await tester.runAsync(() => tester.tap(target));
    await tester.pump();
  }

  Future<void> seed(
    WidgetTester tester,
    Future<void> Function() work,
  ) => tester.runAsync(work).then((_) => tester.pump());

  testWidgets('with no count open it says there is nothing to export', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Nothing to export yet'), findsOneWidget);
    expect(find.text('Share file'), findsNothing);
    expect(find.text('Download'), findsNothing);
  });

  testWidgets('it names the count and its totals', (tester) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('4800888812345', units: 24);
      await counts.recordScan('4800194115817', units: 6);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Export & share'), findsOneWidget);
    expect(find.text('"Bodega count" · 2 items · 30 units'), findsOneWidget);
  });

  testWidgets('csv is selected first and previews the real file', (
    tester,
  ) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('4800888812345', name: 'Kopiko', units: 2);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('bilang-bodega-count.csv'), findsOneWidget);
    expect(find.textContaining('name,barcode,qty'), findsOneWidget);
    expect(find.textContaining('Kopiko,4800888812345,2'), findsOneWidget);
  });

  testWidgets('choosing JSON changes the file name and the preview', (
    tester,
  ) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('JSON'));
    await tester.pumpAndSettle();

    expect(find.text('bilang-bodega-count.json'), findsOneWidget);
    expect(find.textContaining('"app": "Bilang"'), findsOneWidget);
  });

  testWidgets('excel names an xlsx file but previews the csv rendering', (
    tester,
  ) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Excel'));
    await tester.pumpAndSettle();

    expect(find.text('bilang-bodega-count.xlsx'), findsOneWidget);
    expect(find.textContaining('name,barcode,qty'), findsOneWidget);
  });

  testWidgets('sharing hands over the right file name, bytes and type', (
    tester,
  ) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Share file'));
    await settleThroughStorage(tester, () => delivery.sharedName != null);

    expect(delivery.sharedName, 'bilang-bodega-count.csv');
    expect(delivery.sharedMime, 'text/csv');
    expect(utf8.decode(delivery.sharedBytes!), contains('name,barcode,qty'));
    expect(find.textContaining('Shared bilang-bodega-count.csv'), findsOneWidget);
  });

  testWidgets('sharing an xlsx hands over workbook bytes, not csv', (
    tester,
  ) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Excel'));
    await tester.pumpAndSettle();
    await tapLive(tester, find.text('Share file'));
    await settleThroughStorage(tester, () => delivery.sharedName != null);

    expect(delivery.sharedName, 'bilang-bodega-count.xlsx');
    expect(
      delivery.sharedMime,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(delivery.sharedBytes!.take(2).toList(), [0x50, 0x4B]);
  });

  testWidgets('a dismissed share says nothing', (tester) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });
    delivery.outcome = ShareOutcome.dismissed;

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Share file'));
    await settleThroughStorage(tester, () => delivery.sharedName != null);

    expect(find.textContaining('Shared'), findsNothing);
  });

  testWidgets('saving reports success', (tester) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Download'));
    await settleThroughStorage(tester, () => delivery.savedName != null);

    expect(delivery.savedName, 'bilang-bodega-count.csv');
    expect(delivery.savedMime, 'text/csv');
    expect(find.textContaining('Saved bilang-bodega-count.csv'), findsOneWidget);
  });

  testWidgets('backing out of the save dialog says so', (tester) async {
    await seed(tester, () async {
      await counts.startCount('Bodega count', at: DateTime(2026, 8, 28));
      await counts.recordScan('111', units: 1);
    });
    delivery.saveResult = false;

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tapLive(tester, find.text('Download'));
    await settleThroughStorage(tester, () => delivery.savedName != null);

    expect(find.text('Save cancelled'), findsOneWidget);
  });
}
