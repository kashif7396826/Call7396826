/// Mirrors smsRepository.js's listThreads() row shape.
class SmsThread {
  final int contactId;
  final String? firstName;
  final String? lastName;
  final String contactPhone;
  final String lastBody;
  final String lastDirection;
  final DateTime lastAt;
  final int messageCount;

  SmsThread({
    required this.contactId,
    required this.firstName,
    required this.lastName,
    required this.contactPhone,
    required this.lastBody,
    required this.lastDirection,
    required this.lastAt,
    required this.messageCount,
  });

  String get contactName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isEmpty ? contactPhone : name;
  }

  factory SmsThread.fromJson(Map<String, dynamic> json) => SmsThread(
        contactId: json['contact_id'] as int,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        contactPhone: json['contact_phone'] as String? ?? '',
        lastBody: json['last_body'] as String? ?? '',
        lastDirection: json['last_direction'] as String? ?? 'outbound',
        lastAt: DateTime.parse(json['last_at'] as String),
        messageCount: json['message_count'] as int,
      );
}

/// Mirrors smsRepository.js's getConversation() row shape.
class SmsMessage {
  final int id;
  final String provider;
  final String direction; // inbound | outbound
  final String fromNumber;
  final String toNumber;
  final String body;
  final String status;
  final DateTime createdAt;

  SmsMessage({
    required this.id,
    required this.provider,
    required this.direction,
    required this.fromNumber,
    required this.toNumber,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  bool get isOutbound => direction == 'outbound';

  factory SmsMessage.fromJson(Map<String, dynamic> json) => SmsMessage(
        id: json['id'] as int,
        provider: json['provider'] as String? ?? 'twilio',
        direction: json['direction'] as String,
        fromNumber: json['from_number'] as String? ?? '',
        toNumber: json['to_number'] as String? ?? '',
        body: json['body'] as String? ?? '',
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
