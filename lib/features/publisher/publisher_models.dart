/// Mirrors publisherRepository.js's response shapes field-for-field.
class PublisherDashboard {
  final int totalNumbers;
  final int activeNumbers;
  final int inactiveNumbers;
  final int totalCalls;
  final int answeredCalls;
  final int missedCalls;
  final int totalDurationSeconds;
  final List<PublisherCall> recentCalls;

  PublisherDashboard({
    required this.totalNumbers,
    required this.activeNumbers,
    required this.inactiveNumbers,
    required this.totalCalls,
    required this.answeredCalls,
    required this.missedCalls,
    required this.totalDurationSeconds,
    required this.recentCalls,
  });

  factory PublisherDashboard.fromJson(Map<String, dynamic> json) {
    final numberStats = json['numberStats'] as Map<String, dynamic>;
    final callStats = json['callStats'] as Map<String, dynamic>;
    return PublisherDashboard(
      totalNumbers: numberStats['total'] as int,
      activeNumbers: numberStats['active'] as int,
      inactiveNumbers: numberStats['inactive'] as int,
      totalCalls: callStats['total'] as int,
      answeredCalls: callStats['answered'] as int,
      missedCalls: callStats['missed'] as int,
      totalDurationSeconds: callStats['duration'] as int,
      recentCalls: (json['recentCalls'] as List).map((c) => PublisherCall.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}

class PublisherNumberStats {
  final int total;
  final int answered;
  final int missed;
  final int durationSeconds;

  PublisherNumberStats({required this.total, required this.answered, required this.missed, required this.durationSeconds});

  factory PublisherNumberStats.fromJson(Map<String, dynamic> json) => PublisherNumberStats(
        total: json['total'] as int,
        answered: json['answered'] as int,
        missed: json['missed'] as int,
        durationSeconds: json['duration'] as int,
      );
}

class PublisherNumber {
  final int id;
  final String phoneNumber;
  final bool isActive;
  final DateTime? assignedAt;
  final String? campaignName;
  final String? companyName;
  final PublisherNumberStats stats;

  PublisherNumber({
    required this.id,
    required this.phoneNumber,
    required this.isActive,
    required this.assignedAt,
    required this.campaignName,
    required this.companyName,
    required this.stats,
  });

  factory PublisherNumber.fromJson(Map<String, dynamic> json) => PublisherNumber(
        id: json['id'] as int,
        phoneNumber: json['phone_number'] as String,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        assignedAt: json['publisher_assigned_at'] != null ? DateTime.tryParse(json['publisher_assigned_at'] as String) : null,
        campaignName: json['campaign_name'] as String?,
        companyName: json['company_name'] as String?,
        stats: PublisherNumberStats.fromJson(json['stats'] as Map<String, dynamic>),
      );
}

class PublisherCall {
  final int id;
  final String fromNumber;
  final String toNumber;
  final String status;
  final String statusLabel;
  final int durationSeconds;
  final String direction;
  final bool hasRecording;
  final String publisherNumber;
  final String? companyName;
  final String? callerName;
  final DateTime createdAt;

  PublisherCall({
    required this.id,
    required this.fromNumber,
    required this.toNumber,
    required this.status,
    required this.statusLabel,
    required this.durationSeconds,
    required this.direction,
    required this.hasRecording,
    required this.publisherNumber,
    required this.companyName,
    required this.callerName,
    required this.createdAt,
  });

  String get caller => (callerName != null && callerName!.trim().isNotEmpty) ? callerName!.trim() : fromNumber;

  factory PublisherCall.fromJson(Map<String, dynamic> json) {
    final first = json['first_name'] as String?;
    final last = json['last_name'] as String?;
    final name = [first, last].where((s) => s != null && s.isNotEmpty).join(' ');
    return PublisherCall(
      id: json['id'] as int,
      fromNumber: json['from_number'] as String? ?? '',
      toNumber: json['to_number'] as String? ?? '',
      status: json['status'] as String,
      statusLabel: json['status_label'] as String? ?? json['status'] as String,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      direction: json['direction'] as String,
      hasRecording: json['has_recording'] == 1 || json['has_recording'] == true,
      publisherNumber: json['publisher_number'] as String? ?? '',
      companyName: json['company_name'] as String?,
      callerName: name.isEmpty ? null : name,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
