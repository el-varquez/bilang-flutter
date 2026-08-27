import 'package:bilang/features/count/services/scan_armer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int arms;
  late int disarms;

  ScanArmer build({Duration timeout = const Duration(milliseconds: 80)}) {
    arms = 0;
    disarms = 0;
    return ScanArmer(
      onArm: () async => arms++,
      onDisarm: () async => disarms++,
      timeout: timeout,
    );
  }

  test('it starts idle and decodes nothing', () {
    final armer = build();
    expect(armer.value, ScanArmState.idle);
    expect(armer.isArmed, isFalse);
    armer.dispose();
  });

  test('arming starts the camera once', () async {
    final armer = build();
    await armer.arm();
    await armer.arm();

    expect(armer.isArmed, isTrue);
    expect(arms, 1);
    armer.dispose();
  });

  test('the first read is accepted and returns to idle', () async {
    final armer = build();
    await armer.arm();

    expect(await armer.accept(), isTrue);
    expect(armer.value, ScanArmState.idle);
    expect(disarms, 1);
    armer.dispose();
  });

  test('a second read arriving after disarm is refused', () async {
    final armer = build();
    await armer.arm();
    await armer.accept();

    expect(await armer.accept(), isFalse);
    expect(disarms, 1);
    armer.dispose();
  });

  test('a read while idle is refused and starts nothing', () async {
    final armer = build();

    expect(await armer.accept(), isFalse);
    expect(arms, 0);
    expect(disarms, 0);
    armer.dispose();
  });

  test('it disarms itself when nothing is read', () async {
    final armer = build(timeout: const Duration(milliseconds: 40));
    await armer.arm();

    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(armer.value, ScanArmState.idle);
    expect(disarms, 1);
    armer.dispose();
  });

  test('an accepted read cancels the timeout', () async {
    final armer = build(timeout: const Duration(milliseconds: 40));
    await armer.arm();
    await armer.accept();

    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(disarms, 1);
    armer.dispose();
  });
}
