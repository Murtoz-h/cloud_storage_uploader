import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'image_compress_config.dart';
import 'image_compressor.dart';

class ImageLocalSaver {
  ImageLocalSaver._();

  /// Pick from gallery/camera → compress → save to app documents dir.
  /// [relativePath] e.g. `'contacts/entryId/profile.jpg'`
  /// Returns saved [File], or null if user cancels or save fails.
  static Future<File?> pickAndSave({
    required String relativePath,
    BuildContext? context,
    ImageSource? source,
    ImageCompressConfig config = const ImageCompressConfig(),
  }) async {
    final File? original = await ImageCompressor.pickImage(
      context: context,
      source: source,
    );
    if (original == null) return null;
    return _compressAndSave(original, relativePath, config);
  }

  /// Compress an already-held [File] → save to app documents dir.
  static Future<File?> saveFile(
    File file, {
    required String relativePath,
    ImageCompressConfig config = const ImageCompressConfig(),
  }) => _compressAndSave(file, relativePath, config);

  // ── private ──────────────────────────────────────────────────────────────

  static Future<File?> _compressAndSave(
    File original,
    String relativePath,
    ImageCompressConfig config,
  ) async {
    try {
      final File compressed = await ImageCompressor.compressFile(
        original,
        config: config,
      );

      final appDir = await getApplicationDocumentsDirectory();
      final destPath = '${appDir.path}/$relativePath';
      await File(destPath).parent.create(recursive: true);

      final saved = await compressed.copy(destPath);
      debugPrint(
        '[ImageLocalSaver] Saved → $destPath (${(await saved.length()) ~/ 1024}KB)',
      );
      return saved;
    } catch (e) {
      debugPrint('[ImageLocalSaver] Failed: $e');
      return null;
    }
  }

  /// Save raw bytes to the app documents directory.
  static Future<File?> saveBytes({
    required Uint8List bytes,
    required String relativePath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destPath = '${appDir.path}/$relativePath';
      await File(destPath).parent.create(recursive: true);
      final saved = await File(destPath).writeAsBytes(bytes);
      debugPrint(
          '[ImageLocalSaver] saveBytes → $destPath (${bytes.length ~/ 1024}KB)');
      return saved;
    } catch (e) {
      debugPrint('[ImageLocalSaver] saveBytes Failed: $e');
      return null;
    }
  }
}
