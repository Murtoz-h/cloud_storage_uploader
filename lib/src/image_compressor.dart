import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'image_compress_config.dart';

class ImageCompressor {
  ImageCompressor._();

  static final _picker = ImagePicker();

  /// Pick from gallery or camera, return raw [File].
  /// 
  /// Note: If [source] is not provided, a [context] must be provided so the library 
  /// can display a bottom sheet to let the user select between camera and gallery.
  /// 
  /// Returns null if user cancels.
  static Future<File?> pickImage({
    BuildContext? context,
    ImageSource? source,
  }) async {
    ImageSource? selectedSource = source;

    if (selectedSource == null) {
      assert(context != null, 'context must not be null if source is not provided');
      selectedSource = await showModalBottomSheet<ImageSource>(
        context: context!,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (selectedSource == null) return null;
    }


    try {
      final XFile? picked = await _picker.pickImage(source: selectedSource);
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('[ImageCompressor] Pick failed. Error: $e');
      return null;
    }
  }

  /// Compress an existing [File].
  /// This is memory-efficient for apps because it uses native disk I/O.
  /// Falls back to original if compression fails.
  static Future<File> compressFile(
    File file, {
    ImageCompressConfig config = const ImageCompressConfig(),
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = _extensionFromFormat(config.format);
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.$ext';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: config.quality,
        minWidth: config.maxWidth,
        minHeight: config.maxHeight,
        format: config.format,
      );

      if (result == null) {
        debugPrint(
            '[ImageCompressor] Compression result is null, using original.');
        return file;
      }

      return File(result.path);
    } catch (e) {
      debugPrint(
          '[ImageCompressor] Compression failed, using original. Error: $e');
      return file;
    }
  }

  /// Compress raw [Uint8List] bytes directly.
  static Future<Uint8List> compressBytes(
    Uint8List bytes, {
    ImageCompressConfig config = const ImageCompressConfig(),
  }) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        quality: config.quality,
        minWidth: config.maxWidth,
        minHeight: config.maxHeight,
        format: config.format,
      );
    } catch (e) {
      debugPrint(
          '[ImageCompressor] Byte compression failed, using original. Error: $e');
      return bytes;
    }
  }

  // ── private helpers ──

  static String _extensionFromFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.png:
        return 'png';
      case CompressFormat.webp:
        return 'webp';
      case CompressFormat.heic:
        return 'heic';
      default:
        return 'jpg';
    }
  }
}
