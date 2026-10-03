import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _client.post(ApiEndpoints.logout);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(ApiEndpoints.me);
    return response as Map<String, dynamic>;
  }
}
