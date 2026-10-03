import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import 'leave_models.dart';

class LeaveRepository {
  final ApiClient _client;

  LeaveRepository(this._client);

  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    final response = await _client.get(ApiEndpoints.leaveTypes);

    if (response is List) {
      return response
          .map((item) => LeaveTypeModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField
            .map((item) => LeaveTypeModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return (dataField['data'] as List)
            .map((item) => LeaveTypeModel.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<List<LeaveBalanceModel>> getLeaveBalance() async {
    final response = await _client.get(ApiEndpoints.leaveBalance);

    if (response is List) {
      return response
          .map((item) => LeaveBalanceModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField
            .map((item) => LeaveBalanceModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return (dataField['data'] as List)
            .map((item) => LeaveBalanceModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (response['balances'] is List) {
        return (response['balances'] as List)
            .map((item) => LeaveBalanceModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (response.containsKey('remaining_days') ||
          response.containsKey('total_quota') ||
          response.containsKey('total_days')) {
        return [LeaveBalanceModel.fromMap(response)];
      }
    }

    return [];
  }

  Future<List<LeaveRequestModel>> getMyRequests({
    String? status,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (page != null) {
      queryParams['page'] = page;
    }

    final response = await _client.get(
      ApiEndpoints.leaveMyRequests,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => LeaveRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField
            .map((item) => LeaveRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return (dataField['data'] as List)
            .map((item) => LeaveRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (response['requests'] is List) {
        return (response['requests'] as List)
            .map((item) => LeaveRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
    Uint8List? attachmentBytes,
  }) async {
    final formMap = <String, dynamic>{
      'id_leave_types': leaveTypeId,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
    };

    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      final fileName = attachmentPath.split('/').last.split('\\').last;
      formMap['attachment'] = await MultipartFile.fromFile(
        attachmentPath,
        filename: fileName.isNotEmpty ? fileName : 'bukti_izin.jpg',
      );
    } else if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
      formMap['attachment'] = MultipartFile.fromBytes(
        attachmentBytes,
        filename: 'bukti_izin_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final formData = FormData.fromMap(formMap);
    final response = await _client.post(
      ApiEndpoints.leaveRequest,
      data: formData,
    );

    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {'success': true};
  }
}
