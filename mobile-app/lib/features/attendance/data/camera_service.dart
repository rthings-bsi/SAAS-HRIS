import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CameraServiceException implements Exception {
  final String message;
  const CameraServiceException(this.message);

  @override
  String toString() => message;
}

abstract class CameraService {
  Future<XFile?> capturePhoto();
}

class ImagePickerCameraService implements CameraService {
  final ImagePicker _picker;

  ImagePickerCameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<XFile?> capturePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return photo;
    } catch (e) {
      throw CameraServiceException('Gagal membuka kamera: $e');
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return ImagePickerCameraService();
});
