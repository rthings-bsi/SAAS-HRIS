import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Future<SharedPreferences> Function() _prefsProvider;
  void Function()? onUnauthorized;
  static const String tokenKey = 'auth_token';

  AuthInterceptor({
    Future<SharedPreferences> Function()? prefsProvider,
    this.onUnauthorized,
  }) : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';

    final prefs = await _prefsProvider();
    final token = prefs.getString(tokenKey);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final prefs = await _prefsProvider();
      await prefs.remove(tokenKey);
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
