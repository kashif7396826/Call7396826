import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around a configured [Dio] instance — every real network call in this app goes
/// through here. Attaches the access token to every request and transparently refreshes it on
/// a 401 exactly once per request (mirrors services/authService.js's refresh() endpoint:
/// POST /auth/refresh rotates the refresh token, so a concurrent second refresh attempt with
/// the now-consumed old token would fail — [_refreshCompleter] makes concurrent 401s share one
/// in-flight refresh instead of racing each other into that failure).
///
/// On refresh failure, tokens are cleared and [onSessionExpired] fires so the app can bounce
/// back to the login screen — never left showing stale authenticated UI with dead tokens.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // The refresh call itself must never carry a (possibly stale) access token header.
        if (!options.path.contains('/auth/refresh') && !options.path.contains('/auth/login')) {
          final token = await TokenStorage.instance.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final isAuthEndpoint = error.requestOptions.path.contains('/auth/');
        if (error.response?.statusCode == 401 && !isAuthEndpoint) {
          try {
            await _refreshTokens();
            final retryToken = await TokenStorage.instance.accessToken;
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $retryToken';
            final response = await _dio.fetch(retryOptions);
            return handler.resolve(response);
          } catch (_) {
            await TokenStorage.instance.clear();
            onSessionExpired?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  /// Set by the auth layer (see features/auth/auth_provider.dart) to react to a session that
  /// can no longer be refreshed — e.g. navigate back to the login screen.
  void Function()? onSessionExpired;

  Completer<void>? _refreshCompleter;

  Future<void> _refreshTokens() async {
    // Share one in-flight refresh across concurrent 401s instead of each racing its own
    // POST /auth/refresh — the backend rotates (consumes) the refresh token on every call, so
    // a second concurrent attempt with the same (now-stale) token would fail outright.
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<void>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await TokenStorage.instance.refreshToken;
      if (refreshToken == null) throw ApiException(message: 'No session to refresh.');

      final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      await TokenStorage.instance.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );
      completer.complete();
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) => _wrap(() => _dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(String path, {dynamic data}) => _wrap(() => _dio.post<T>(path, data: data));

  Future<Response<T>> patch<T>(String path, {dynamic data}) => _wrap(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> delete<T>(String path) => _wrap(() => _dio.delete<T>(path));

  /// Not exposed via get/post/etc. above — used directly by features/calls/call_repository.dart
  /// for the recording proxy, which streams bytes rather than returning JSON.
  Dio get raw => _dio;

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponseData(e.response!.data, e.response!.statusCode);
      }
      throw ApiException(message: 'Network error — check your connection and try again.');
    }
  }
}
