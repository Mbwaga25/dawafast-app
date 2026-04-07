import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the camera and returns the [File] object of the captured image.
  /// Returns null if user cancels or image capture fails.
  Future<File?> capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint("Camera capture error: $e");
      return null;
    }
  }

  /// Opens the gallery and returns the [File] object of the picked image.
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint("Gallery picker error: $e");
      return null;
    }
  }
}
