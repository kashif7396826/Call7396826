/// Mirrors authService.js's sanitizeUser() exactly — every field it returns, nothing it strips
/// (password_hash never leaves the server at all).
class User {
  final int id;
  final int? clientId;
  final String name;
  final String? companyName;
  final String? companyLogoPath; // full URL — authService.js's sanitizeUser() resolves the stored relative path
  final String email;
  final String? phone;
  final String timezone;
  final bool notifyNewCall;
  final String role; // super_admin | client_admin | client_agent | publisher
  final bool isActive;
  final String? twilioClientIdentity;
  final bool totpEnabled;

  User({
    required this.id,
    required this.clientId,
    required this.name,
    required this.companyName,
    required this.companyLogoPath,
    required this.email,
    required this.phone,
    required this.timezone,
    required this.notifyNewCall,
    required this.role,
    required this.isActive,
    required this.twilioClientIdentity,
    required this.totpEnabled,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        clientId: json['client_id'] as int?,
        name: json['name'] as String,
        companyName: json['company_name'] as String?,
        companyLogoPath: json['company_logo_path'] as String?,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        timezone: (json['timezone'] as String?) ?? 'UTC',
        notifyNewCall: json['notify_new_call'] == 1 || json['notify_new_call'] == true,
        role: json['role'] as String,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        twilioClientIdentity: json['twilio_client_identity'] as String?,
        totpEnabled: json['totpEnabled'] as bool? ?? false,
      );

  bool get isPublisher => role == 'publisher';
  bool get isSuperAdmin => role == 'super_admin';
  bool get isClientAdmin => role == 'client_admin';
}
