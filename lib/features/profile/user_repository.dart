import '../../core/network/api_client.dart';
import '../auth/user.dart';

/// Direct port of the real GET/PATCH /users/me and POST /users/me/password endpoints
/// (userController.js — verified server-side against real data before this app existed).
class UserRepository {
  final _api = ApiClient.instance;

  Future<User> updateProfile({required String name, required String email}) async {
    final response = await _api.patch('/users/me', data: {'name': name, 'email': email});
    return User.fromJson((response.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  /// Throws ApiException with code INVALID_PASSWORD if [currentPassword] is wrong — same 401
  /// the backend returns after a real bcrypt.compare() against the stored hash.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _api.post('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
