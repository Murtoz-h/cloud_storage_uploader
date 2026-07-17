import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_storage_uploader/cloud_storage_uploader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Storage Uploader Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UploaderExamplePage(),
    );
  }
}

class UploaderExamplePage extends StatefulWidget {
  const UploaderExamplePage({super.key});

  @override
  State<UploaderExamplePage> createState() => _UploaderExamplePageState();
}

class _UploaderExamplePageState extends State<UploaderExamplePage> {
  String? _statusText;
  File? _localImageFile;
  String? _remoteImageUrl;

  Future<void> _pickAndCompress() async {
    setState(() {
      _statusText = 'Picking and compressing...';
    });

    // Provide context because source is null (will show bottom sheet)
    final file = await ImageUploadManager.pickAndCompress(
      context: context,
      config: const ImageCompressConfig(quality: 70),
    );

    if (file != null) {
      setState(() {
        _localImageFile = file;
        _remoteImageUrl = null;
        _statusText =
            'Picked and compressed successfully!\\nPath: ${file.path}';
      });
    } else {
      setState(() {
        _statusText = 'User cancelled picking or compression failed.';
      });
    }
  }

  Future<void> _pickCompressAndUpload() async {
    setState(() {
      _statusText = 'Picking, compressing, and uploading...';
    });

    // We must provide context if we don't provide source.
    final result = await ImageUploadManager.pickCompressAndUpload(
      context: context,
      storagePath: 'test_uploads/${DateTime.now().millisecondsSinceEpoch}.jpg',
      config: const ImageCompressConfig(quality: 70),
    );

    if (result != null) {
      setState(() {
        _remoteImageUrl = result.downloadUrl;
        _localImageFile = null;
        _statusText =
            'Upload Success!\\nOriginal Size: ${result.originalSizeKb} KB\\nCompressed Size: ${result.compressedSizeKb} KB';
      });
    } else {
      setState(() {
        _statusText =
            'Upload cancelled or failed. Make sure Firebase is configured!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploader Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_localImageFile != null) ...[
              const Text(
                'Local File:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Image.file(_localImageFile!, height: 200),
              const SizedBox(height: 16),
            ] else if (_remoteImageUrl != null) ...[
              const Text(
                'Remote URL:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Image.network(_remoteImageUrl!, height: 200),
              const SizedBox(height: 16),
            ],

            Text(
              _statusText ?? 'Select an action below',
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickAndCompress,
              icon: const Icon(Icons.compress),
              label: const Text('Pick and Compress (Local only)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickCompressAndUpload,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Pick, Compress & Upload (Firebase)'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Note: Uploading requires a valid Firebase configuration in this example app.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
