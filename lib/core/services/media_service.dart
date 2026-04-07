import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Opens the camera and returns the [XFile] object of the captured image.
  /// Returns null if user cancels or image capture fails.
  Future<XFile?> capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );

      return photo;
    } catch (e) {
      debugPrint("Camera capture error: $e");
      return null;
    }
  }

  /// Opens the gallery and returns the [XFile] object of the picked image.
  Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );

      return image;
    } catch (e) {
      debugPrint("Gallery picker error: $e");
      return null;
    }
  }
}
