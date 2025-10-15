import 'package:shared_preferences/shared_preferences.dart';
import 'token_store.dart';

class TokenStoreImpl implements TokenStore {
  static const _kRefresh = 'refresh_token';
  String? _accessInMemory;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _accessInMemory = access;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRefresh, refresh);
  }

  @override
  Future<Map<String, String?>> readTokens() async {
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString(_kRefresh);
    return {'access': _accessInMemory, 'refresh': refresh};
  }

  @override
  Future<void> clearTokens() async {
    _accessInMemory = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kRefresh);
  }
}
