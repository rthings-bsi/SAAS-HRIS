import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio, AuthInterceptor? interceptor})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(interceptor ?? AuthInterceptor());
  }

  Dio get dio => _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    final body = response.data;
    if (body is Map) {
      final success = body['success'] as bool? ?? true;
      if (!success) {
        final rawErrors = body['errors'];
        final errors = rawErrors is Map<String, dynamic>
            ? rawErrors
            : (rawErrors is Map ? Map<String, dynamic>.from(rawErrors) : null);
        throw ApiException(
          message: body['message'] as String? ?? 'Terjadi kesalahan pada server.',
          statusCode: response.statusCode,
          errors: errors,
        );
      }
      return body['data'] ?? body;
    }
    return body;
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      if (statusCode == 401) {
        return const UnauthorizedException();
      }

      dynamic body = response.data;
      if (body is List<int>) {
        try {
          final decoded = utf8.decode(body);
          body = jsonDecode(decoded);
        } catch (_) {}
      }

      if (body is Map) {
        final message = body['message'] as String? ?? 'Terjadi kesalahan sistem.';
        final rawErrors = body['errors'];
        final errors = rawErrors is Map<String, dynamic>
            ? rawErrors
            : (rawErrors is Map ? Map<String, dynamic>.from(rawErrors) : null);

        if (statusCode == 422) {
          return ValidationException(
            message: message,
            errors: errors,
          );
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          errors: errors,
        );
      }

      return ApiException(
        message: 'Permintaan gagal (${response.statusCode}).',
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: error.message ?? 'Kesalahan tidak diketahui.',
    );
  }
}
