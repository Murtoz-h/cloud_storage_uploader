import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressConfig {
  final int quality;
  final int maxWidth;
  final int maxHeight;
  final CompressFormat format;

  const ImageCompressConfig({
    this.quality = 80,
    this.maxWidth = 1280,
    this.maxHeight = 1280,
    this.format = CompressFormat.jpeg,
  });
}
