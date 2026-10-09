/// Mirrors campaignController.js's list() response — real aggregates from the
/// campaigns/contacts/calls tables, no placeholder numbers.
class Campaign {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int contactCount;
  final int callCount;
  final int answeredCount;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.contactCount,
    required this.callCount,
    required this.answeredCount,
    required this.createdAt,
  });

  /// null when there have been no calls yet — distinct from a real 0% answer rate.
  double? get answerRate => callCount > 0 ? answeredCount / callCount : null;

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        contactCount: int.parse(json['contact_count'].toString()),
        callCount: int.parse(json['call_count'].toString()),
        answeredCount: int.parse(json['answered_count'].toString()),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
