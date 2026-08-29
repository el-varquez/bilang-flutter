import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ShareOutcome { shared, dismissed, unknown }

abstract class FileDelivery {
  Future<ShareOutcome> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });

  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

class PlatformFileDelivery implements FileDelivery {
  const PlatformFileDelivery();

  @override
  Future<ShareOutcome> share({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
      ),
    );

    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.shared,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return uri != null;
  }
}
