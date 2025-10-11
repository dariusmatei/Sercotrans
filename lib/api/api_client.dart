import 'dart:async';
import 'package:dio/dio.dart';
import '../config.dart';
import '../utils/jwt.dart';
import '../data/token_store.dart';

class ApiClient {
  final Dio dio;
  final TokenStore _store;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  final _pending = <Completer<void>>[];

  ApiClient(this._store)
      : dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        final tokens = await _store.readTokens();
        final access = tokens['access'];
        if (access != null && access.isNotEmpty) {
          opts.headers['Authorization'] = 'Bearer ' + access;
        }
        handler.next(opts);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          try {
            await _refreshTokens();
            final clone = await dio.request(
              err.requestOptions.path,
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
              options: Options(
                method: err.requestOptions.method,
                headers: err.requestOptions.headers,
              ),
            );
            return handler.resolve(clone);
          } catch (_) {
            await _store.clearTokens();
          }
        }
        handler.next(err);
      },
    ));
  }

  Future<void> bootstrap() async {
    final tokens = await _store.readTokens();
    final access = tokens['access'];
    final refresh = tokens['refresh'];
    if (access != null && refresh != null) {
      _scheduleRefresh(access, refresh);
    }
  }

  Future<void> setTokens(String access, String refresh) async {
    await _store.saveTokens(access: access, refresh: refresh);
    _scheduleRefresh(access, refresh);
  }

  void _scheduleRefresh(String access, String refresh) {
    _refreshTimer?.cancel();
    final exp = jwtExpiry(access);
    if (exp == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final due = (exp - AppConfig.refreshSkewSeconds) - now;
    final duration = Duration(seconds: due > 1 ? due : 1);
    _refreshTimer = Timer(duration, () {
      _refreshTokens();
    });
  }

  Future<void> _refreshTokens() async {
    if (_isRefreshing) {
      final c = Completer<void>();
      _pending.add(c);
      await c.future;
      return;
    }

    _isRefreshing = true;
    try {
      final tokens = await _store.readTokens();
      final refresh = tokens['refresh'];
      if (refresh == null) throw Exception('No refresh token');
      final resp = await dio.post('/auth/refresh', data: {'refreshToken': refresh});
      final data = resp.data as Map;
      final newAccess = data['accessToken'] as String;
      final newRefresh = (data['refreshToken'] as String?) ?? refresh;
      await _store.saveTokens(access: newAccess, refresh: newRefresh);
      _scheduleRefresh(newAccess, newRefresh);
      for (final c in _pending) {
        if (!c.isCompleted) c.complete();
      }
      _pending.clear();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> clear() async {
    _refreshTimer?.cancel();
    await _store.clearTokens();
  }
}
