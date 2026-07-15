class ImageUploadResult {
  final String downloadUrl;
  final int originalSizeKb;
  final int compressedSizeKb;
  final int savedPercent;

  ImageUploadResult({
    required this.downloadUrl,
    required this.originalSizeKb,
    required this.compressedSizeKb,
    required this.savedPercent,
  });

  @override
  String toString() => 'ImageUploadResult(url: $downloadUrl, '
      'original: ${originalSizeKb}KB, '
      'compressed: ${compressedSizeKb}KB, '
      'saved: $savedPercent%)';
}
