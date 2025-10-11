import 'token_store_impl.dart' if (dart.library.html) 'token_store_web.dart';

abstract class TokenStore {
  Future<void> saveTokens({required String access, required String refresh});
  Future<Map<String, String?>> readTokens(); // keys: access, refresh
  Future<void> clearTokens();
}

TokenStore tokenStore() => TokenStoreImpl();
