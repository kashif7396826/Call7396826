/// Mirrors callRepository.js's SELECT_BASE field-for-field.
class Call {
  final int id;
  final int clientId;
  final String provider; // twilio | telnyx | ringcentral
  final int? contactId;
  final String? contactFirstName;
  final String? contactLastName;
  final String? numberLabel;
  final String? trackingNumber;
  final int? handledBy;
  final String? handledByName;
  final String direction; // inbound | outbound
  final String channel; // number | browser | trunk | mobile
  final String fromNumber;
  final String toNumber;
  final String status;
  final String? disposition;
  final int? durationSeconds;
  final bool hasRecording;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  Call({
    required this.id,
    required this.clientId,
    required this.provider,
    required this.contactId,
    required this.contactFirstName,
    required this.contactLastName,
    required this.numberLabel,
    required this.trackingNumber,
    required this.handledBy,
    required this.handledByName,
    required this.direction,
    required this.channel,
    required this.fromNumber,
    required this.toNumber,
    required this.status,
    required this.disposition,
    required this.durationSeconds,
    required this.hasRecording,
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
  });

  String get contactName {
    final name = [contactFirstName, contactLastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isEmpty ? (direction == 'outbound' ? toNumber : fromNumber) : name;
  }

  factory Call.fromJson(Map<String, dynamic> json) => Call(
        id: json['id'] as int,
        clientId: json['client_id'] as int,
        provider: json['provider'] as String? ?? 'twilio',
        contactId: json['contact_id'] as int?,
        contactFirstName: json['contact_first_name'] as String?,
        contactLastName: json['contact_last_name'] as String?,
        numberLabel: json['number_label'] as String?,
        trackingNumber: json['tracking_number'] as String?,
        handledBy: json['handled_by'] as int?,
        handledByName: json['handled_by_name'] as String?,
        direction: json['direction'] as String,
        channel: json['channel'] as String,
        fromNumber: json['from_number'] as String? ?? '',
        toNumber: json['to_number'] as String? ?? '',
        status: json['status'] as String,
        disposition: json['disposition'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
        hasRecording: json['has_recording'] == 1 || json['has_recording'] == true,
        startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
        endedAt: json['ended_at'] != null ? DateTime.tryParse(json['ended_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({required this.page, required this.limit, required this.total, required this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        page: json['page'] as int,
        limit: json['limit'] as int,
        total: json['total'] as int,
        totalPages: json['totalPages'] as int,
      );
}

class CallListResult {
  final List<Call> calls;
  final Pagination pagination;
  CallListResult(this.calls, this.pagination);
}
