import '../../core/network/api_client.dart';
import 'call.dart';

/// Every method here hits the real Node API — routes/callRoutes.js. Recording bytes are never
/// fetched into a JSON model; see streamRecordingUrl()'s doc comment.
class CallRepository {
  final _api = ApiClient.instance;

  Future<CallListResult> list({int page = 1, int limit = 25, String? direction, String? status}) async {
    final response = await _api.get('/calls', query: {
      'page': page,
      'limit': limit,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
    });
    final data = response.data as Map<String, dynamic>;
    final calls = (data['calls'] as List).map((c) => Call.fromJson(c as Map<String, dynamic>)).toList();
    return CallListResult(calls, Pagination.fromJson(data['pagination'] as Map<String, dynamic>));
  }

  Future<Call> getOne(int id) async {
    final response = await _api.get('/calls/$id');
    return Call.fromJson((response.data as Map<String, dynamic>)['call'] as Map<String, dynamic>);
  }

  /// GET /calls/incoming/token — mints a fresh Twilio Voice Access Token for this agent. Call
  /// this every time the Voice SDK needs (re-)registering, e.g. on app start once logged in and
  /// whenever a call is about to be placed — access tokens are short-lived by design.
  Future<({String token, String identity})> getVoiceToken() async {
    final response = await _api.get('/calls/incoming/token');
    final data = response.data as Map<String, dynamic>;
    return (token: data['token'] as String, identity: data['identity'] as String);
  }

  Future<void> endCall(int id) => _api.post('/calls/$id/end');

  Future<void> transferCall(int id, String to) => _api.post('/calls/$id/transfer', data: {'to': to});

  Future<void> pauseRecording(int id) => _api.post('/calls/$id/recording/pause');
  Future<void> resumeRecording(int id) => _api.post('/calls/$id/recording/resume');
  Future<void> stopRecording(int id) => _api.post('/calls/$id/recording/stop');

  /// The recording itself is streamed bytes (audio/mpeg), not JSON — GET /calls/:id/recording
  /// proxies it server-side and never hands out a raw provider URL (mirrors
  /// recordings/play.php). The player widget should point directly at this authenticated URL
  /// (with the Authorization header attached, same as every other request) rather than this
  /// repository buffering the whole file into memory.
  String recordingUrl(int callId) => '/calls/$callId/recording';
}
