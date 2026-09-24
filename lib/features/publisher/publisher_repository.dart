import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../auth/user.dart';
import 'publisher_models.dart';

/// Every method here hits the real Node API — routes/publisherRoutes.js. Scoped entirely to
/// this publisher's own assigned numbers server-side; there's no clientId/scope param to pass
/// here on purpose, matching how the backend derives it (see publisherRepository.js on the
/// Node side).
class PublisherRepository {
  final _api = ApiClient.instance;

  Future<PublisherDashboard> getDashboard() async {
    final response = await _api.get('/publisher/dashboard');
    return PublisherDashboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PublisherNumber>> getNumbers() async {
    final response = await _api.get('/publisher/numbers');
    final data = (response.data as Map<String, dynamic>)['numbers'] as List;
    return data.map((n) => PublisherNumber.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<List<PublisherCall>> getCalls({int? numberId}) async {
    final response = await _api.get('/publisher/calls', query: {if (numberId != null) 'numberId': numberId});
    final data = (response.data as Map<String, dynamic>)['calls'] as List;
    return data.map((c) => PublisherCall.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Same authenticated, proxied-audio pattern as CallRepository.recordingUrl() — the
  /// Authorization header is attached exactly like every other request, never a raw provider URL.
  String recordingUrl(int callId) => '/publisher/calls/$callId/recording';

  /// Same data as the login response's own user object (GET /auth/me), scoped through the
  /// publisher-only route so the profile screen never needs the staff-only /users/me, which
  /// 403s for this role server-side (requireNonPublisher()).
  Future<User> getMe() async {
    final response = await _api.get('/publisher/me');
    return User.fromJson((response.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  /// Direct port of publisher/settings.php's update_profile action (PATCH /publisher/me).
  /// multipart/form-data — [logoFile] is optional; when null, the existing logo (if any) is
  /// left untouched server-side (same as leaving the PHP page's file input empty).
  Future<User> updateProfile({
    required String name,
    required String email,
    String? companyName,
    String? phone,
    required String timezone,
    required bool notifyNewCall,
    File? logoFile,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'email': email,
      if (companyName != null) 'companyName': companyName,
      if (phone != null) 'phone': phone,
      'timezone': timezone,
      'notifyNewCall': notifyNewCall.toString(),
      if (logoFile != null) 'companyLogo': await MultipartFile.fromFile(logoFile.path, filename: logoFile.path.split('/').last),
    });
    final response = await _api.patch('/publisher/me', data: form);
    return User.fromJson((response.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  /// Same wiring as UserRepository.changePassword(), just the publisher-only endpoint — throws
  /// ApiException with code INVALID_PASSWORD on a real bcrypt.compare() mismatch server-side.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _api.post('/publisher/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
}
