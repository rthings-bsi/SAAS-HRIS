import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';

const String serverBaseUrlPrefKey = 'server_base_url';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final initialBaseUrlProvider = Provider<String>((ref) {
  return ApiEndpoints.baseUrl;
});

class ServerBaseUrlNotifier extends StateNotifier<String> {
  ServerBaseUrlNotifier(super.initial);

  Future<void> setBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.trim();
    if (cleanUrl.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(serverBaseUrlPrefKey, cleanUrl);
    } catch (_) {}
    if (cleanUrl != state) {
      state = cleanUrl;
    }
  }

  Future<void> resetToDefault() async {
    await setBaseUrl(ApiEndpoints.baseUrl);
  }
}

final serverBaseUrlProvider =
    StateNotifierProvider<ServerBaseUrlNotifier, String>((ref) {
  final initial = ref.watch(initialBaseUrlProvider);
  return ServerBaseUrlNotifier(initial);
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    prefsProvider: () => SharedPreferences.getInstance(),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final interceptor = ref.watch(authInterceptorProvider);
  final initialBaseUrl = ref.watch(initialBaseUrlProvider);
  final client = ApiClient(interceptor: interceptor, baseUrl: initialBaseUrl);
  ref.listen<String>(serverBaseUrlProvider, (previous, next) {
    client.updateBaseUrl(next);
  });
  return client;
});
