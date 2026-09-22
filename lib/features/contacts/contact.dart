/// Mirrors contactRepository.js's SELECT_BASE field-for-field.
class Contact {
  final int id;
  final int clientId;
  final String firstName;
  final String? lastName;
  final String phone;
  final String? email;
  final String? company;
  final String stage; // new | contacted | qualified | won | lost
  final int? campaignId;
  final String? campaignName;
  final int? assignedTo;
  final String? assignedToName;
  final String? notes;
  final bool onDncList;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.clientId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.company,
    required this.stage,
    required this.campaignId,
    required this.campaignName,
    required this.assignedTo,
    required this.assignedToName,
    required this.notes,
    required this.onDncList,
    required this.createdAt,
  });

  String get fullName => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as int,
        clientId: json['client_id'] as int,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String?,
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        company: json['company'] as String?,
        stage: json['stage'] as String? ?? 'new',
        campaignId: json['campaign_id'] as int?,
        campaignName: json['campaign_name'] as String?,
        assignedTo: json['assigned_to'] as int?,
        assignedToName: json['assigned_to_name'] as String?,
        notes: json['notes'] as String?,
        onDncList: json['on_dnc_list'] == 1 || json['on_dnc_list'] == true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

const kContactStages = ['new', 'contacted', 'qualified', 'won', 'lost'];
