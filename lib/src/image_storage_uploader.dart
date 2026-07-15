import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'image_upload_result.dart';

class ImageStorageUploader {
  ImageStorageUploader._();

  /// Upload [compressed] file to Firebase Storage at [storagePath].
  /// Requires [original] only for computing size comparison stats.
  /// Dynamically assigns metadata content-type depending on the ImageCompressFormat.
  /// Returns [ImageUploadResult] with download URL and size info.
  static Future<ImageUploadResult> upload(
    File original,
    File compressed, {
    required String storagePath,
    required CompressFormat format,
    Map<String, String>? customMetadata,
  }) async {
    final ref = FirebaseStorage.instance.ref(storagePath);

    String contentType;
    switch (format) {
      case CompressFormat.png:
        contentType = 'image/png';
        break;
      case CompressFormat.webp:
        contentType = 'image/webp';
        break;
      case CompressFormat.heic:
        contentType = 'image/heic';
        break;
      case CompressFormat.jpeg:
        contentType = 'image/jpeg';
        break;
    }

    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMetadata,
    );

    // Streams directly from file, avoiding high RAM usage on Android/iOS
    final task = await ref.putFile(compressed, metadata);
    final url = await task.ref.getDownloadURL();

    final originalLength = original.lengthSync();
    final compressedLength = compressed.lengthSync();

    final origKb = (originalLength / 1024).round();
    final compKb = (compressedLength / 1024).round();
    final saved = originalLength > 0
        ? ((1 - compressedLength / originalLength) * 100).round()
        : 0;

    debugPrint(
      '[ImageStorageUploader] ${origKb}KB → ${compKb}KB (saved $saved%)',
    );

    return ImageUploadResult(
      downloadUrl: url,
      originalSizeKb: origKb,
      compressedSizeKb: compKb,
      savedPercent: saved,
    );
  }
}
