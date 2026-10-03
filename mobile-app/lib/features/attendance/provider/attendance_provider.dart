import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_provider.dart';
import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';
import '../data/camera_service.dart';
import '../data/location_service.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AttendanceRepository(client);
});

final todayAttendanceProvider =
    FutureProvider.autoDispose<TodayAttendanceData>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final map = await repo.getTodayAttendance();
  return TodayAttendanceData.fromMap(map);
});

final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final now = DateTime.now();
  final list = await repo.getAttendanceHistory(month: now.month, year: now.year);
  return list.map((item) {
    if (item is Map<String, dynamic>) {
      return AttendanceRecord.fromMap(item);
    }
    return AttendanceRecord(date: item.toString());
  }).toList();
});

class AttendanceActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AttendanceActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AttendanceActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AttendanceActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AttendanceActionNotifier extends StateNotifier<AttendanceActionState> {
  final AttendanceRepository _repo;
  final LocationService _locationService;
  final CameraService _cameraService;
  final Ref _ref;

  AttendanceActionNotifier(
    this._repo,
    this._locationService,
    this._cameraService,
    this._ref,
  ) : super(const AttendanceActionState());

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  Future<bool> recordAttendance({
    required bool isClockIn,
    String? overridePhotoPath,
    Uint8List? overridePhotoBytes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    try {
      // 1. Request & retrieve GPS coordinates via geolocator
      final position = await _locationService.getCurrentPosition();

      // 2. Check position.isMocked: immediately halt if fake GPS detected
      if (position.isMocked) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'Presensi ditolak. Terdeteksi penggunaan Fake GPS / Mock Location.',
        );
        return false;
      }

      // 3. Request camera and capture selfie
      String? photoPath = overridePhotoPath;
      Uint8List? photoBytes = overridePhotoBytes;

      if (photoPath == null && photoBytes == null) {
        final photo = await _cameraService.capturePhoto();
        if (photo == null) {
          // User cancelled photo capture
          state = state.copyWith(isLoading: false);
          return false;
        }
        photoPath = photo.path;
      }

      // 4. Send multipart request to backend
      if (isClockIn) {
        await _repo.clockIn(
          latitude: position.latitude,
          longitude: position.longitude,
          photoPath: photoPath,
          photoBytes: photoBytes,
          isMocked: position.isMocked,
        );
      } else {
        await _repo.clockOut(
          latitude: position.latitude,
          longitude: position.longitude,
          photoPath: photoPath,
          photoBytes: photoBytes,
          isMocked: position.isMocked,
        );
      }

      // 5. Success feedback & refresh today's attendance status
      final successMsg = isClockIn
          ? 'Presensi masuk berhasil dicatat.'
          : 'Presensi pulang berhasil dicatat.';

      state = state.copyWith(
        isLoading: false,
        successMessage: successMsg,
      );

      _ref.invalidate(todayAttendanceProvider);
      _ref.invalidate(attendanceHistoryProvider);
      return true;
    } catch (e) {
      String msg = 'Gagal mencatat presensi.';
      if (e is ApiException) {
        msg = e.userFriendlyMessage;
      } else if (e is LocationServiceException || e is CameraServiceException) {
        msg = e.toString();
      } else {
        msg = e.toString().replaceFirst('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }
}

final attendanceActionProvider =
    StateNotifierProvider<AttendanceActionNotifier, AttendanceActionState>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  final cameraService = ref.watch(cameraServiceProvider);
  return AttendanceActionNotifier(
    repo,
    locationService,
    cameraService,
    ref,
  );
});
