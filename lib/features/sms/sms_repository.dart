import '../../core/network/api_client.dart';
import '../contacts/contact.dart';
import 'sms_models.dart';

class SmsRepository {
  final _api = ApiClient.instance;

  Future<List<SmsThread>> getThreads() async {
    final response = await _api.get('/sms/threads');
    final data = (response.data as Map<String, dynamic>)['threads'] as List;
    return data.map((t) => SmsThread.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<({Contact contact, List<SmsMessage> messages})> getConversation(int contactId) async {
    final response = await _api.get('/sms/threads/$contactId');
    final data = response.data as Map<String, dynamic>;
    return (
      contact: Contact.fromJson(data['contact'] as Map<String, dynamic>),
      messages: (data['messages'] as List).map((m) => SmsMessage.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  /// Real send via the backend's real Twilio Messages API call — same DNC/client-suspension
  /// checks as outbound calling, see smsController.js.
  Future<void> sendMessage(int contactId, String body) =>
      _api.post('/sms/threads/$contactId', data: {'body': body});
}
