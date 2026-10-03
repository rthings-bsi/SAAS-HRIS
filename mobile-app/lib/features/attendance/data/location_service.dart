import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

abstract class LocationService {
  Future<Position> getCurrentPosition();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Layanan lokasi (GPS) tidak aktif. Silakan aktifkan GPS perangkat Anda.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Izin lokasi ditolak. Izin diperlukan untuk memverifikasi lokasi presensi.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengizinkan akses lokasi.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});
