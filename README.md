# Cloud Storage Uploader

A comprehensive Flutter package for seamlessly handling image picking, compression, and uploading to Firebase Storage. This package provides a unified pipeline to manage user images efficiently, saving both bandwidth and storage space.

## Features

- **End-to-End Pipeline**: Pick from gallery/camera, compress, and upload in a single function call.
- **Efficient Compression**: Uses `flutter_image_compress` for high-performance native image compression.
- **Firebase Storage Integration**: Built-in support for uploading to Firebase Storage.
- **Smart Uploads**: Utility to check if an image is local before uploading (useful for profile updates).
- **Local Caching**: Ability to pick, compress, and save images to the local app directory for offline-first architectures.
- **Granular Control**: Standalone methods for picking, compressing, or uploading if you don't need the full pipeline.

## Getting started

To use this package, you need to add it to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  cloud_storage_uploader: ^0.0.1
```

Since this package depends on `firebase_storage` and `image_picker`, make sure you have configured Firebase and the required permissions for picking images in your Flutter project.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

## Usage

Here are some common usage examples for `cloud_storage_uploader`.

### 1. Complete Pipeline (Pick, Compress, and Upload)

The easiest way to let a user pick an image and upload it to a specific path in Firebase Storage.

```dart
import 'package:cloud_storage_uploader/cloud_storage_uploader.dart';

Future<void> uploadProfilePicture() async {
  final result = await ImageUploadManager.pickCompressAndUpload(
    storagePath: 'users/123/profile.jpg',
    config: const ImageCompressConfig(
      quality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    ),
  );

  if (result != null) {
    print('Upload successful! Download URL: ${result.downloadUrl}');
    print('Original size: ${result.originalSizeBytes} bytes');
    print('Compressed size: ${result.compressedSizeBytes} bytes');
  } else {
    print('Upload cancelled or failed.');
  }
}
```

### 2. Compress and Upload an Existing File

If you already have a `File` object (e.g., from another picker):

```dart
import 'dart:io';
import 'package:cloud_storage_uploader/cloud_storage_uploader.dart';

Future<void> uploadExistingFile(File myFile) async {
  final result = await ImageUploadManager.compressAndUpload(
    myFile,
    storagePath: 'uploads/my_image.jpg',
  );

  if (result != null) {
    print('Uploaded: ${result.downloadUrl}');
  }
}
```

### 3. Smart Profile Image Update

When updating a user's profile, the image path might be an existing remote URL or a newly picked local file. This method handles both automatically:

```dart
import 'package:cloud_storage_uploader/cloud_storage_uploader.dart';

Future<void> updateProfile(String currentImageUrlOrLocalPath) async {
  final newUrl = await ImageUploadManager.uploadProfileOrGenericImageIfLocal(
    currentImageUrlOrLocalPath,
    storagePath: 'users/123/profile.jpg',
  );

  print('New profile image URL: $newUrl');
}
```

## Additional information

For more granular control, `ImageUploadManager` also exposes individual methods:
- `ImageUploadManager.pickImage()`
- `ImageUploadManager.compressFile()`
- `ImageUploadManager.compressBytes()`
- `ImageUploadManager.pickAndSaveLocal()`
- `ImageUploadManager.saveFileLocal()`
- `ImageUploadManager.upload()`

Contributions and bug reports are welcome! Please check the GitHub repository if you encounter any problems.
