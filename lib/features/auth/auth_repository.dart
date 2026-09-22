import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import 'user.dart';

/// Result of POST /auth/login — either tokens+user, or a requiresTotp challenge. Mirrors
/// authController.js's login() response shape exactly (this extra step isn't a client-side
/// invention — the backend genuinely requires it for any account with 2FA enabled, same as the
/// website, since skipping it for mobile would be a real security regression).
class LoginResult {
  final bool requiresTotp;
  final String? mfaToken;
  final User? user;

  LoginResult.totpRequired(this.mfaToken)
      : requiresTotp = true,
        user = null;

  LoginResult.success(this.user)
      : requiresTotp = false,
        mfaToken = null;
}

class AuthRepository {
  final _api = ApiClient.instance;

  Future<LoginResult> login(String email, String password) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
      'deviceInfo': 'flutter-mobile',
    });
    final data = response.data as Map<String, dynamic>;
    if (data['requiresTotp'] == true) {
      return LoginResult.totpRequired(data['mfaToken'] as String);
    }
    await TokenStorage.instance.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return LoginResult.success(User.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<User> verifyTotp(String mfaToken, String code) async {
    final response = await _api.post('/auth/login/verify-totp', data: {
      'mfaToken': mfaToken,
      'code': code,
      'deviceInfo': 'flutter-mobile',
    });
    final data = response.data as Map<String, dynamic>;
    await TokenStorage.instance.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> fetchCurrentUser() async {
    final response = await _api.get('/auth/me');
    return User.fromJson((response.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final refreshToken = await TokenStorage.instance.refreshToken;
    try {
      await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
    } finally {
      // Clear locally regardless of whether the server call succeeded — a failed logout
      // request must never leave the user stuck "logged in" on their own device.
      await TokenStorage.instance.clear();
    }
  }
}
