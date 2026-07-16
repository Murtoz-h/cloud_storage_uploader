import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_compress_config.dart';
import 'image_upload_result.dart';
import 'image_compressor.dart';
import 'image_storage_uploader.dart';
import 'image_local_saver.dart';

/// The primary facade for the cloud storage uploader library.
///
/// This manager provides a single entry point for all image handling operations,
/// combining picking, compressing, local saving, and cloud uploading into seamless
/// pipelines or offering them as standalone utilities.
///
/// **Main Pipelines**:
/// - [pickCompressAndUpload]: The complete flow from user selection to cloud storage.
/// - [compressAndUploadFile]: For when you already have an image [File] that needs uploading.
/// - [compressAndUploadBytes]: For when you have an image in memory as [Uint8List].
/// - [uploadIfLocal]: Smartly handles mixed URLs/local paths (e.g., for user profile updates).
///
/// **Standalone Utilities**:
/// For more granular control, the manager exposes individual tools:
/// - [pickImage]: Just pick an image.
/// - [compressFile] / [compressBytes]: Just compress.
/// - [pickAndSaveLocal] / [saveFileLocal]: Pick/compress and save to the local app directory.
/// - [upload]: Raw upload to Firebase Storage.
class ImageUploadManager {
  ImageUploadManager._();

  /// Executes the full image pipeline: pick from gallery/camera, compress, and upload to Firebase.
  ///
  /// This is the easiest way to handle user uploads. It manages the entire flow safely
  /// and returns null if the user cancelled picking or if an error occurred.
  ///
  /// - [storagePath]: The exact path in Firebase Storage where the file will be saved (e.g., `'users/123/profile.jpg'`).
  /// - [source]: The source of the image (camera or gallery). If null, a bottom sheet will prompt the user.
  /// - [config]: Settings for compression (quality, max width/height, format).
  /// - [customMetadata]: Optional custom metadata to attach to the Firebase Storage object.
  ///
  /// Returns an [ImageUploadResult] containing the download URL and compression stats,
  /// or null if the operation was cancelled or failed.
  static Future<ImageUploadResult?> pickCompressAndUpload({
    required String storagePath,
    BuildContext? context,
    ImageSource? source,
    ImageCompressConfig config = const ImageCompressConfig(),
    Map<String, String>? customMetadata,
  }) async {
    try {
      final File? original = await ImageCompressor.pickImage(
        context: context,
        source: source,
      );
      if (original == null) return null; // user cancelled picking.

      final File compressed = await ImageCompressor.compressFile(
        original,
        config: config,
      );

      return await ImageStorageUploader.upload(
        original,
        compressed,
        storagePath: storagePath,
        format: config.format,
        customMetadata: customMetadata,
      );
    } catch (e, stackTrace) {
      debugPrint('[ImageUploadManager] Pipeline failed: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  /// Compresses an already-picked [File] and uploads it to Firebase Storage.
  ///
  /// Useful when you acquire an image file outside of this library's picking methods
  /// but still want the benefits of compression and standardized uploading.
  ///
  /// - [original]: The raw image file to be compressed and uploaded.
  /// - [storagePath]: The target path in Firebase Storage.
  /// - [config]: Settings for compression.
  /// - [customMetadata]: Optional custom metadata to attach.
  ///
  /// Returns an [ImageUploadResult] or null if the operation failed.
  static Future<ImageUploadResult?> compressAndUploadFile(
    File original, {
    required String storagePath,
    ImageCompressConfig config = const ImageCompressConfig(),
    Map<String, String>? customMetadata,
  }) async {
    try {
      final File compressed = await ImageCompressor.compressFile(
        original,
        config: config,
      );

      return await ImageStorageUploader.upload(
        original,
        compressed,
        storagePath: storagePath,
        format: config.format,
        customMetadata: customMetadata,
      );
    } catch (e, stackTrace) {
      debugPrint('[ImageUploadManager] Upload failed for cached File: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  /// Compresses a [Uint8List] (e.g., from memory or web) and uploads it to Firebase Storage.
  ///
  /// - [original]: The raw bytes to be compressed and uploaded.
  /// - [storagePath]: The target path in Firebase Storage.
  /// - [config]: Settings for compression.
  /// - [customMetadata]: Optional custom metadata to attach.
  ///
  /// Returns an [ImageUploadResult] or null if the operation failed.
  static Future<ImageUploadResult?> compressAndUploadBytes(
    Uint8List original, {
    required String storagePath,
    ImageCompressConfig config = const ImageCompressConfig(),
    Map<String, String>? customMetadata,
  }) async {
    try {
      final Uint8List compressed = await ImageCompressor.compressBytes(
        original,
        config: config,
      );

      return await ImageStorageUploader.uploadBytes(
        original,
        compressed,
        storagePath: storagePath,
        format: config.format,
        customMetadata: customMetadata,
      );
    } catch (e, stackTrace) {
      debugPrint('[ImageUploadManager] Upload failed for bytes: $e');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  /// A smart utility to upload an image only if it is a local file.
  ///
  /// When dealing with forms (like an edit profile screen), the current image path might be
  /// an existing remote URL (already uploaded) or a new local file path.
  /// This function checks the path:
  /// - If it's remote (`http://`, `https://`), it returns the original URL immediately.
  /// - If it's local (standard path or `file://`), it compresses and uploads the file, returning the new remote URL.
  ///
  /// - [localOrRemotePath]: The string path to check and upload if necessary.
  /// - [storagePath]: The target path in Firebase Storage if an upload occurs.
  ///
  /// Returns the remote URL string (either the original or the newly uploaded one).
  static Future<String?> uploadIfLocal(
    String? localOrRemotePath, {
    required String storagePath,
    ImageCompressConfig config = const ImageCompressConfig(),
    Map<String, String>? customMetadata,
  }) async {
    if (localOrRemotePath == null ||
        localOrRemotePath.isEmpty ||
        localOrRemotePath.startsWith('http://') ||
        localOrRemotePath.startsWith('https://')) {
      return localOrRemotePath;
    }

    // It's a local path. Handle optional file:// prefix.
    final pathStr = localOrRemotePath.startsWith('file://')
        ? Uri.parse(localOrRemotePath).toFilePath()
        : localOrRemotePath;

    final file = File(pathStr);
    if (!await file.exists()) {
      debugPrint('[ImageUploadManager] Local file not found: $pathStr');
      return localOrRemotePath;
    }

    final result = await compressAndUploadFile(
      file,
      storagePath: storagePath,
      config: config,
      customMetadata: customMetadata,
    );

    return result?.downloadUrl ?? localOrRemotePath;
  }

  // ── Standalone Utilities (Exposed by Reference) ──

  /// Prompts the user to pick an image from the gallery or camera.
  ///
  /// Returns the raw [File], or null if the user cancels.
  /// Requires a `BuildContext` if `source` is not provided to show the selector sheet.
  static const pickImage = ImageCompressor.pickImage;

  /// Compresses an existing [File] using native disk I/O, which is highly memory-efficient.
  ///
  /// Returns the compressed [File], or the original file if compression fails.
  static const compressFile = ImageCompressor.compressFile;

  /// Compresses raw image bytes directly in memory.
  ///
  /// Returns the compressed bytes, or the original bytes if compression fails.
  static const compressBytes = ImageCompressor.compressBytes;

  /// Picks an image from the specified [source], compresses it, and saves it permanently
  /// to the app's documents directory under the given [relativePath].
  ///
  /// Useful for offline-first architectures.
  static const pickAndSaveLocal = ImageLocalSaver.pickAndSave;

  /// Compresses an existing [File] and saves it permanently to the app's documents directory.
  static const saveFileLocal = ImageLocalSaver.saveFile;

  /// Saves raw image bytes permanently to the app's documents directory.
  static const saveBytesLocal = ImageLocalSaver.saveBytes;

  /// Uploads a [compressed] file to Firebase Storage.
  ///
  /// Attaches the correct content-type based on the given `format`.
  /// The `original` file is only used to compute size savings stats.
  static const upload = ImageStorageUploader.upload;

  /// Uploads raw [compressed] bytes to Firebase Storage.
  ///
  /// Attaches the correct content-type based on the given `format`.
  /// The `original` bytes are only used to compute size savings stats.
  /// Most of time its not going to use
  static const uploadBytes = ImageStorageUploader.uploadBytes;
}
