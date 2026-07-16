## 0.0.4

* Added null-safety support

## 0.0.3

* Fixed a `BuildContext` assertion error by allowing `context` to be passed to `pickCompressAndUpload`.
* Added `compressAndUploadBytes` to support uploading `Uint8List` image data.
* Added `saveBytesLocal` and `uploadBytes` utility methods for direct byte handling.
* Renamed `compressAndUpload` to `compressAndUploadFile`.
* Renamed `uploadProfileOrGenericImageIfLocal` to `uploadIfLocal` for clarity.

## 0.0.2

* Updated pubspec.yaml file.
* Added homepage and repository fields.


## 0.0.1

* Initial release: Includes full image upload pipeline with compression, picking, and Firebase Storage integration.
