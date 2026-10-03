import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'payroll_models.dart';

class PayrollRepository {
  final ApiClient _client;
  final Future<Directory> Function()? docsDirProvider;

  PayrollRepository(this._client, {this.docsDirProvider});

  Future<List<PayrollSlipModel>> getMySlips() async {
    final response = await _client.get(ApiEndpoints.payrollMySlips);

    if (response is List) {
      return response
          .map((item) => PayrollSlipModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic>) {
      final dataField = response['data'];
      if (dataField is List) {
        return dataField
            .map((item) => PayrollSlipModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (dataField is Map<String, dynamic> && dataField['data'] is List) {
        return (dataField['data'] as List)
            .map((item) => PayrollSlipModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } else if (response['slips'] is List) {
        return (response['slips'] as List)
            .map((item) => PayrollSlipModel.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<String> downloadSlipPdf(int slipId) async {
    final response = await _client.get(
      ApiEndpoints.payrollMySlipDownload(slipId),
      options: Options(responseType: ResponseType.bytes),
    );

    final List<int> bytes;
    if (response is List<int>) {
      bytes = response;
    } else if (response is List) {
      bytes = response.cast<int>();
    } else if (response is Map<String, dynamic>) {
      final message = response['message'] as String? ?? 'Gagal mengunduh berkas slip gaji.';
      throw ApiException(message: message);
    } else {
      throw const ApiException(message: 'Berkas PDF slip gaji kosong atau tidak ditemukan.');
    }

    if (bytes.isEmpty) {
      throw const ApiException(message: 'Berkas PDF slip gaji kosong.');
    }

    final docsFn = docsDirProvider;
    final Directory dir = docsFn != null
        ? await docsFn()
        : await getApplicationDocumentsDirectory();
    final String targetPath = '${dir.path}/slip_gaji_$slipId.pdf';
    final file = File(targetPath);
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
