import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import 'overtime_models.dart';

class OvertimeRepository {
  final ApiClient _client;

  OvertimeRepository(this._client);

  Future<List<OvertimeRequestModel>> getMyRequests({
    String? status,
    String? month,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (month != null && month.isNotEmpty) {
      queryParams['month'] = month;
    }
    if (page != null) {
      queryParams['page'] = page;
    }

    final response = await _client.get(
      ApiEndpoints.myOvertimeRequests,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField
            .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return (dataField['data'] as List)
            .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (response['requests'] is List) {
        return (response['requests'] as List)
            .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> applyOvertime({
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    final payload = {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
    };

    final response = await _client.post(
      ApiEndpoints.applyOvertime,
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> applyOvertimeBatch({
    required List<Map<String, dynamic>> entries,
    required String reason,
  }) async {
    final payload = {
      'entries': entries,
      'reason': reason,
    };

    final response = await _client.post(
      ApiEndpoints.applyOvertime,
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> submitOvertimeForm({
    required List<Map<String, dynamic>> entries,
    required String reason,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final hasFileBytes = attachmentBytes != null && attachmentBytes.isNotEmpty;
    final hasFilePath = attachmentPath != null && attachmentPath.isNotEmpty;

    if (hasFileBytes || hasFilePath) {
      final formMap = <String, dynamic>{
        'entries': jsonEncode(entries),
        'reason': reason,
      };
      if (overtimeType != null && overtimeType.isNotEmpty) {
        formMap['overtime_type'] = overtimeType;
      }
      if (reasonCategory != null && reasonCategory.isNotEmpty) {
        formMap['reason_category'] = reasonCategory;
      }

      final safeName = (attachmentName != null && attachmentName.isNotEmpty)
          ? attachmentName
          : 'lampiran_${DateTime.now().millisecondsSinceEpoch}';

      if (hasFileBytes) {
        formMap['attachment'] = MultipartFile.fromBytes(
          attachmentBytes,
          filename: safeName,
        );
      } else if (attachmentPath != null && attachmentPath.isNotEmpty) {
        formMap['attachment'] = await MultipartFile.fromFile(
          attachmentPath,
          filename: safeName,
        );
      }

      final response = await _client.post(
        ApiEndpoints.applyOvertime,
        data: FormData.fromMap(formMap),
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': true};
    }

    final payload = <String, dynamic>{
      'entries': entries,
      'reason': reason,
    };
    if (overtimeType != null && overtimeType.isNotEmpty) {
      payload['overtime_type'] = overtimeType;
    }
    if (reasonCategory != null && reasonCategory.isNotEmpty) {
      payload['reason_category'] = reasonCategory;
    }

    final response = await _client.post(
      ApiEndpoints.applyOvertime,
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> updateOvertime({
    required int id,
    required String date,
    String? endDate,
    required String startTime,
    required String endTime,
    required String reason,
    List<Map<String, dynamic>>? entries,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
    bool removeAttachment = false,
  }) async {
    final hasFileBytes = attachmentBytes != null && attachmentBytes.isNotEmpty;
    final hasFilePath = attachmentPath != null && attachmentPath.isNotEmpty;
    final hasEntries = entries != null && entries.isNotEmpty;

    if (hasFileBytes || hasFilePath) {
      final formMap = <String, dynamic>{
        'reason': reason,
      };
      if (hasEntries) {
        formMap['entries'] = jsonEncode(entries);
      } else {
        formMap['date'] = date;
        formMap['end_date'] =
            (endDate != null && endDate.isNotEmpty) ? endDate : date;
        formMap['start_time'] = startTime;
        formMap['end_time'] = endTime;
      }
      if (overtimeType != null && overtimeType.isNotEmpty) {
        formMap['overtime_type'] = overtimeType;
      }
      if (reasonCategory != null && reasonCategory.isNotEmpty) {
        formMap['reason_category'] = reasonCategory;
      }

      final safeName = (attachmentName != null && attachmentName.isNotEmpty)
          ? attachmentName
          : 'lampiran_${DateTime.now().millisecondsSinceEpoch}';

      if (hasFileBytes) {
        formMap['attachment'] = MultipartFile.fromBytes(
          attachmentBytes,
          filename: safeName,
        );
      } else if (attachmentPath != null && attachmentPath.isNotEmpty) {
        formMap['attachment'] = await MultipartFile.fromFile(
          attachmentPath,
          filename: safeName,
        );
      }

      final response = await _client.post(
        ApiEndpoints.updateOvertimeMultipart(id),
        data: FormData.fromMap(formMap),
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': true};
    }

    final payload = <String, dynamic>{
      'reason': reason,
    };
    if (hasEntries) {
      payload['entries'] = entries;
    } else {
      payload['date'] = date;
      payload['end_date'] =
          (endDate != null && endDate.isNotEmpty) ? endDate : date;
      payload['start_time'] = startTime;
      payload['end_time'] = endTime;
    }
    if (overtimeType != null && overtimeType.isNotEmpty) {
      payload['overtime_type'] = overtimeType;
    }
    if (reasonCategory != null && reasonCategory.isNotEmpty) {
      payload['reason_category'] = reasonCategory;
    }
    if (removeAttachment) {
      payload['remove_attachment'] = true;
    }

    final response = await _client.put(
      ApiEndpoints.updateOvertime(id),
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> cancelOvertime({
    required int id,
    String? reason,
  }) async {
    final payload = <String, dynamic>{};
    if (reason != null && reason.trim().isNotEmpty) {
      payload['reason'] = reason.trim();
    }

    final response = await _client.post(
      ApiEndpoints.cancelOvertime(id),
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<List<OvertimeRequestModel>> getApprovals({
    String? status,
    String? date,
    int? page,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }
    if (page != null) {
      queryParams['page'] = page;
    }

    final response = await _client.get(
      ApiEndpoints.overtimeApprovals,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response is List) {
      return response
          .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField
            .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return (dataField['data'] as List)
            .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (response['requests'] is List) {
        return (response['requests'] as List)
            .map((item) => OvertimeRequestModel.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> takeApprovalAction({
    required int id,
    required String action,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'action': action,
    };
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _client.post(
      ApiEndpoints.overtimeAction(id),
      data: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }
}
