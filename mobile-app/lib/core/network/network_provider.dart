import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    prefsProvider: () => ref.read(sharedPreferencesProvider.future),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final interceptor = ref.watch(authInterceptorProvider);
  return ApiClient(interceptor: interceptor);
});
