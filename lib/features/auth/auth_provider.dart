import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/realtime/socket_service.dart';
import '../../core/storage/token_storage.dart';
import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus { unknown, awaitingTotp, authenticated, unauthenticated }

/// App-wide auth state. `AuthStatus.unknown` is the real "checking stored tokens" state on
/// cold start — the splash/root widget watches this instead of guessing whether a token
/// exists, so there's never a flash of the login screen for an already-logged-in user.
class AuthProvider extends ChangeNotifier {
  final _repository = AuthRepository();

  AuthStatus status = AuthStatus.unknown;
  User? currentUser;
  String? _pendingMfaToken;
  String? errorMessage;
  bool isLoading = false;

  AuthProvider() {
    ApiClient.instance.onSessionExpired = () {
      status = AuthStatus.unauthenticated;
      currentUser = null;
      notifyListeners();
    };
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await TokenStorage.instance.accessToken;
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      // A stored access token could be expired — fetchCurrentUser() will trigger the
      // ApiClient's own refresh-on-401 interceptor transparently if so, so this either
      // succeeds with a valid session or genuinely fails (refresh token also dead/revoked).
      currentUser = await _repository.fetchCurrentUser();
      status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStorage.instance.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.login(email, password);
      if (result.requiresTotp) {
        _pendingMfaToken = result.mfaToken;
        status = AuthStatus.awaitingTotp;
        return true;
      }
      currentUser = result.user;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyTotp(String code) async {
    if (_pendingMfaToken == null) {
      errorMessage = 'MFA session expired — log in again.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _repository.verifyTotp(_pendingMfaToken!, code);
      status = AuthStatus.authenticated;
      _pendingMfaToken = null;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    SocketService.instance.disconnect();
    await _repository.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Called after a successful PATCH /users/me so every screen watching this provider (e.g.
  /// the dashboard's "Hi, {name}" greeting) reflects the change immediately, without needing
  /// its own GET /auth/me round-trip.
  void updateCurrentUser(User user) {
    currentUser = user;
    notifyListeners();
  }
}
