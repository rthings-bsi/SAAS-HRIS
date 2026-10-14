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
  ServerBaseUrlNotifier() : super(ApiEndpoints.baseUrl);

  Future<void> setBaseUrl(String newUrl) async {
    // Server telah dipatenkan ke domain API resmi
    state = ApiEndpoints.baseUrl;
  }

  Future<void> resetToDefault() async {
    state = ApiEndpoints.baseUrl;
  }
}

final serverBaseUrlProvider =
    StateNotifierProvider<ServerBaseUrlNotifier, String>((ref) {
  return ServerBaseUrlNotifier();
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    prefsProvider: () => SharedPreferences.getInstance(),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final interceptor = ref.watch(authInterceptorProvider);
  return ApiClient(interceptor: interceptor, baseUrl: ApiEndpoints.baseUrl);
});
