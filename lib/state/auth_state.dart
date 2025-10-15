import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../data/token_store.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final bool busy;
  final String? error;
  final Set<String> roles;

  const AuthState({
    required this.isAuthenticated,
    this.userName,
    this.busy = false,
    this.error,
    this.roles = const {},
  });

  AuthState copyWith({bool? isAuthenticated, String? userName, bool? busy, String? error, Set<String>? roles}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      busy: busy ?? this.busy,
      error: error,
      roles: roles ?? this.roles,
    );
  }

  bool hasRole(String r) => roles.contains(r);

  static const initial = AuthState(isAuthenticated: false, busy: false);
}

final tokenStoreProvider = Provider<TokenStore>((_) => tokenStore());
final apiClientProvider = Provider<ApiClient>((ref) {
  final store = ref.watch(tokenStoreProvider);
  final client = ApiClient(store);
  unawaited(client.bootstrap());
  return client;
});

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

class AuthController extends StateNotifier<AuthState> {
  final AuthApi _api;
  final ApiClient _client;
  final TokenStore _store;

  AuthController(this._api, this._client, this._store) : super(AuthState.initial) {
    _markAuthenticatedIfPossible();
  }

  Future<void> _markAuthenticatedIfPossible() async {
    final tokens = await _store.readTokens();
    final hasRefresh = (tokens['refresh'] ?? '').isNotEmpty;
    if (hasRefresh) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final res = await _api.login(email: email, password: password);
      await _client.setTokens(res.accessToken, res.refreshToken);
      state = state.copyWith(isAuthenticated: true, userName: res.userName, busy: false, roles: res.roles);
    } catch (e) {
      state = state.copyWith(busy: false, error: 'Autentificare eșuată');
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(busy: true);
    await _api.logout();
    state = AuthState.initial;
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authApiProvider), ref.watch(apiClientProvider), ref.watch(tokenStoreProvider));
});
