# Image Upload Module Documentation

This document explains how to use the Image Upload utility module (located in `utils/image_upload`), its main facilities, and its limitations. 

## Table of Contents
1. [Overview](#overview)
2. [How to Use](#how-to-use)
    - [1. Full Pipeline (Pick, Compress, Upload)](#1-full-pipeline-pick-compress-upload)
    - [2. Pick with Custom Compression settings](#2-pick-with-custom-compression-settings)
    - [3. Compress and Upload an Existing File](#3-compress-and-upload-an-existing-file)
3. [Facilities (Pros & Features)](#facilities-pros--features)
4. [Cons (Limitations & Drawbacks)](#cons-limitations--drawbacks)

---

## Overview

The Image Upload module abstracts away the complexities of picking an image from the gallery/camera, compressing it down to a predictable size, and uploading it directly to Firebase Storage. 

It is divided into 5 clear classes:
- `ImageCompressConfig`: Configuration object for quality and dimensions.
- `ImageCompressor`: Handles picking and compressing `File`s and `Uint8List`s.
- `ImageStorageUploader`: Handles Firebase Storage metadata and uploading.
- `ImageUploadManager`: The facade coordinating picking -> compressing -> uploading.
- `ImageUploadResult`: The return object holding the URL and analytic size stats.

---

## How to Use

The easiest way to interact with the module is through `ImageUploadManager`.

### 1. Full Pipeline (Pick, Compress, Upload)
Automatically opens the device gallery, compresses the image down to 80% quality (default), and uploads it to your desired Firebase Storage path.

```dart
import 'utils/image_upload/image_upload_manager.dart';

Future<void> updateProfilePicture() async {
  final result = await ImageUploadManager.pickCompressAndUpload(
    storagePath: 'users/123/profile.jpg',
  );

  if (result != null) {
    print('Uploaded URL: ${result.downloadUrl}');
    print('Saved space: ${result.savedPercent}%');
  } else {
    print('User cancelled the picker.');
  }
}
```

### 2. Pick with Custom Compression settings
You can change the image source (e.g., Camera) and define custom compression settings (WebP, higher quality, different dimensions). You can also append custom metadata to the Firebase Storage reference.

```dart
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'utils/image_upload/image_upload_manager.dart';
import 'utils/image_upload/image_compress_config.dart';

Future<void> submitHighResPhoto() async {
  final result = await ImageUploadManager.pickCompressAndUpload(
    storagePath: 'high_res_photos/photo123.webp',
    source: ImageSource.camera, // Pick from camera instead
    config: const ImageCompressConfig(
      quality: 95,
      maxWidth: 1920,
      maxHeight: 1920,
      format: CompressFormat.webp, 
    ),
    customMetadata: {
      'uploaded_by': 'admin',
      'purpose': 'verification',
    },
  );
}
```

### 3. Compress and Upload an Existing File
If you already picked an image somewhere else in your app (or have a file cached), you can bypass the picker and directly feed the `dart:io` `File` to the manager.

```dart
import 'dart:io';
import 'utils/image_upload/image_upload_manager.dart';

Future<void> uploadCachedFile(File myExistingFile) async {
  final result = await ImageUploadManager.compressAndUpload(
    myExistingFile,
    storagePath: 'cache_uploads/file.jpg',
  );

  print('Available at: ${result.downloadUrl}');
}
```

---

## Facilities (Pros & Features)

1. **Facade Pattern (Easy to Use)**: `ImageUploadManager` completely abstracts the 3-step process (Pick -> Compress -> Upload) into a single line of code.
2. **Separation of Concerns**: Despite having an easy API, the underlying logic is perfectly chunked. If you ever need to just compress an image without uploading it, you can call `ImageCompressor` directly.
3. **Android & iOS Memory Optimized**: The module uses `compressAndGetFile` and `putFile()` sequentially. Instead of loading an entire 15MB 4K photo into RAM via byte arrays (which causes Out-Of-Memory crashes on older mobile devices), it streams data straight from the native camera disk storage to the compressed output disk location, and then pipes that disk file directly over the Firebase network sockets.
4. **Dynamic Metadata Support**: `ImageStorageUploader` automatically infers the Firebase `contentType` (`image/png`, `image/webp`, `image/heic`, etc.) based on your compression configurations.
5. **Robust Exception Handling**: The entire pipeline restricts crashes by operating inside graceful `try-catch` structures. Denied permissions or network failures simply trigger a `debugPrint` and safely return `null` back to the UI.
6. **Fallback Mechanism**: If the native compressor fails for any reason, the pipeline intelligently prevents crashing and defaults to uploading the original, uncompressed file.
7. **Bandwidth Analytics provided out-of-the-box**: The `ImageUploadResult` class automatically calculates how many KBs were saved during the compression process compared to the original payload, which is great for analytics, logging, and debugging.

## Cons (Limitations & Drawbacks)

1. **Direct Coupling to Firebase Storage**: `ImageStorageUploader` imports and utilizes `firebase_storage` directly. To migrate to an S3 bucket or a custom backend, this class will need to be heavily refactored or swapped entirely.
2. **Intentionally lacks Web Support**: To achieve extreme mobile RAM efficiency, the codebase heavily utilizes native mobile `dart:io` I/O File references. Because of this, it can not be compiled onto a Flutter Web environment.
3. **No Multi-Image Support**: The pipeline currently only picks and uploads a single image. To handle multiple images concurrently, the developer has to manually trigger the manager in custom loops.
