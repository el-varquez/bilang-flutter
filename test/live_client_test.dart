import 'dart:convert';
import 'dart:io';

import 'package:bilang/services/live_client.dart';
import 'package:bilang/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;
  late LocalStore storage;
  late LiveClient live;
  late HttpServer server;
  final received = <Map<String, Object?>>[];
  var respond = true;
  var respondWith = 200;

  Future<void> pumpUntil(bool Function() done) async {
    for (var turn = 0; turn < 300; turn++) {
      if (done()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('condition never became true');
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bilang_live_');
    Hive.init(dir.path);
    storage = await LocalStore.open();
    live = LiveClient(
      storage,
      timeout: const Duration(milliseconds: 300),
      retryDelay: const Duration(milliseconds: 50),
    );
    received.clear();
    respond = true;
    respondWith = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      received.add({
        'method': request.method,
        'contentType': request.headers.contentType?.mimeType,
        'body': jsonDecode(body),
      });
      if (!respond) return;
      request.response.statusCode = respondWith;
      await request.response.close();
    });
  });

  tearDown(() async {
    live.dispose();
    await server.close(force: true);
    await Hive.close();
    await dir.delete(recursive: true);
  });

  String url() => 'http://${server.address.host}:${server.port}/scans';

  test('a scan posts as json the moment it reads', () async {
    await storage.setLiveUrl(url());
    live.send(
      session: 'Bodega count',
      barcode: '4800888812345',
      name: 'Kopiko',
      qty: 3,
    );
    await pumpUntil(() => received.length == 1);

    expect(received.single['method'], 'POST');
    expect(received.single['contentType'], 'application/json');
    final body = received.single['body'] as Map<String, Object?>;
    expect(body['app'], 'Bilang');
    expect(body['session'], 'Bodega count');
    expect(body['barcode'], '4800888812345');
    expect(body['name'], 'Kopiko');
    expect(body['qty'], 3);
    expect(DateTime.tryParse(body['at']! as String), isNotNull);
    await pumpUntil(() => live.status.value == LiveStatus.live);
  });

  test('no endpoint means no traffic', () async {
    live.send(session: 'Bodega count', barcode: '111', qty: 1);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(received, isEmpty);
    expect(live.status.value, LiveStatus.off);
  });

  test('an endpoint on file reads as live before anything is sent', () async {
    await storage.setLiveUrl(url());
    live.refresh();

    expect(live.status.value, LiveStatus.live);
    expect(received, isEmpty);
  });

  test('a failing endpoint queues, retries, and preserves order', () async {
    await storage.setLiveUrl(url());
    respondWith = 500;
    live.send(session: 'Bodega count', barcode: 'first', qty: 1);
    await pumpUntil(() => live.status.value == LiveStatus.retrying);
    live.send(session: 'Bodega count', barcode: 'second', qty: 1);

    respondWith = 200;
    await pumpUntil(
      () => received.any(
        (hit) => (hit['body']! as Map)['barcode'] == 'second',
      ),
    );

    final barcodes = [
      for (final hit in received) (hit['body']! as Map)['barcode'],
    ];
    expect(barcodes.sublist(barcodes.length - 2), ['first', 'second']);
    await pumpUntil(() => live.status.value == LiveStatus.live);
  });

  test('an endpoint that hangs times out into retrying', () async {
    await storage.setLiveUrl(url());
    respond = false;
    live.send(session: 'Bodega count', barcode: '111', qty: 1);

    await pumpUntil(() => live.status.value == LiveStatus.retrying);
  });

  test('a probe posts a test-marked payload and reports success', () async {
    final ok = await live.probe(url());

    expect(ok, isTrue);
    expect(received.single['method'], 'POST');
    expect(received.single['contentType'], 'application/json');
    final body = received.single['body'] as Map<String, Object?>;
    expect(body['app'], 'Bilang');
    expect(body['test'], true);
    expect(DateTime.tryParse(body['at']! as String), isNotNull);
    expect(body.containsKey('barcode'), isFalse);
    expect(body.containsKey('qty'), isFalse);
    expect(live.status.value, LiveStatus.off);
  });

  test('a probe reports a refusing endpoint', () async {
    respondWith = 500;

    expect(await live.probe(url()), isFalse);
  });

  test('a probe times out on a hanging endpoint', () async {
    respond = false;

    expect(await live.probe(url()), isFalse);
  });

  test('a probe of a garbage url fails without throwing', () async {
    expect(await live.probe('not a url'), isFalse);
    expect(received, isEmpty);
  });

  test('clearing the endpoint drops the queue and goes quiet', () async {
    await storage.setLiveUrl(url());
    respondWith = 500;
    live.send(session: 'Bodega count', barcode: '111', qty: 1);
    await pumpUntil(() => live.status.value == LiveStatus.retrying);

    await storage.setLiveUrl('');
    live.refresh();
    await pumpUntil(() => live.status.value == LiveStatus.off);

    final before = received.length;
    respondWith = 200;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(live.status.value, LiveStatus.off);
    expect(received.length, before);
  });
}
