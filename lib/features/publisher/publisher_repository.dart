import '../../core/network/api_client.dart';
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
}
