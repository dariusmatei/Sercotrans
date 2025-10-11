import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_store.dart';

class TokenStoreImpl implements TokenStore {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  @override
  Future<Map<String, String?>> readTokens() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    return {'access': access, 'refresh': refresh};
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
