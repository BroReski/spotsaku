/// Camera & gallery service wrapping `image_picker`.
///
/// Returns the temporary path of the picked image. The repository copies
/// the file into the app's documents directory so the path persists.
library;

import 'package:image_picker/image_picker.dart';

class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final _picker = ImagePicker();

  /// Opens the device camera and returns the captured image path, or
  /// `null` when the user cancels.
  Future<String?> takePhoto() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
    return xFile?.path;
  }

  /// Opens the gallery and returns the selected image path, or `null`
  /// when the user cancels.
  Future<String?> pickFromGallery() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    return xFile?.path;
  }
}
