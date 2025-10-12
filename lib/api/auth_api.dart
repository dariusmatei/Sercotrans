import '../config.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  Future<({String accessToken, String refreshToken, String userName, Set<String> roles})> login({
    required String email,
    required String password,
  }) async {
    final resp = await client.dio.post(
      AppConfig.apiBaseUrl + '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = resp.data as Map;
    final access = data['accessToken'] as String;
    final refresh = data['refreshToken'] as String;
    final name = (data['user']?['name'] as String?) ?? email.split('@').first;
    final rolesRaw = (data['user']?['roles'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{'user'};
    return (accessToken: access, refreshToken: refresh, userName: name, roles: rolesRaw);
  }

  Future<void> logout() async {
    try {
      await client.dio.post('/auth/logout');
    } catch (_) {}
    await client.clear();
  }
}
