import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class AttendanceRepository {
  final ApiClient _client;

  AttendanceRepository(this._client);

  Future<Map<String, dynamic>> getTodayAttendance() async {
    final response = await _client.get(ApiEndpoints.attendanceToday);
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }

  Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
    String? photoPath,
    Uint8List? photoBytes,
    bool isMocked = false,
  }) async {
    final formMap = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'device_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'is_mocked': isMocked,
    };

    if (photoPath != null && photoPath.isNotEmpty) {
      formMap['photo'] = await MultipartFile.fromFile(
        photoPath,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } else if (photoBytes != null && photoBytes.isNotEmpty) {
      formMap['photo'] = MultipartFile.fromBytes(
        photoBytes,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final formData = FormData.fromMap(formMap);
    final response = await _client.post(
      ApiEndpoints.attendanceClockIn,
      data: formData,
    );
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }

  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
    String? photoPath,
    Uint8List? photoBytes,
    bool isMocked = false,
  }) async {
    final formMap = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'device_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'is_mocked': isMocked,
    };

    if (photoPath != null && photoPath.isNotEmpty) {
      formMap['photo'] = await MultipartFile.fromFile(
        photoPath,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } else if (photoBytes != null && photoBytes.isNotEmpty) {
      formMap['photo'] = MultipartFile.fromBytes(
        photoBytes,
        filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final formData = FormData.fromMap(formMap);
    final response = await _client.post(
      ApiEndpoints.attendanceClockOut,
      data: formData,
    );
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }

  Future<List<dynamic>> getAttendanceHistory({
    int? month,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    final response = await _client.get(
      ApiEndpoints.attendanceHistory,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField;
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return dataField['data'] as List<dynamic>;
      }
    }
    return [];
  }
}
