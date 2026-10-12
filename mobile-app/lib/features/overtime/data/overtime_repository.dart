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
}
