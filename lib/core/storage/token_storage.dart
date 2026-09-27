import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens live in the platform keystore (Android Keystore / iOS Keychain) via
/// flutter_secure_storage — never SharedPreferences, never a plain file. Mirrors how seriously
/// the backend treats these (services/authService.js's refresh-token rotation-on-use).
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  // flutter_secure_storage 11.x's default AndroidOptions() already uses strong encryption
  // (AES-GCM with RSA-OAEP key wrapping) unconditionally — the old encryptedSharedPreferences
  // flag this constructor took doesn't exist anymore because that behavior is no longer
  // optional, found against a real Windows build 2026-09-27 (the API had genuinely moved since
  // this code was written, exactly the kind of drift the README warned would need fixing).
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
