import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../auth/user.dart';
import 'publisher_repository.dart';

/// Direct port of publisher/settings.php's "Profile & Company" form — the richer publisher-only
/// field set (company name/logo, phone, timezone, notify-on-new-call) alongside name/email.
/// Deliberately separate from features/profile/edit_profile_screen.dart, not a variant of it —
/// that screen hits the staff-only /users/me, which 403s for a publisher server-side.
class PublisherEditProfileScreen extends StatefulWidget {
  const PublisherEditProfileScreen({super.key});

  @override
  State<PublisherEditProfileScreen> createState() => _PublisherEditProfileScreenState();
}

class _PublisherEditProfileScreenState extends State<PublisherEditProfileScreen> {
  // Same list userValidators.js's PUBLISHER_TIMEZONES carries — kept as an exact copy for the
  // same reason that file's own comment gives (the PHP/Node source isn't reachable from this
  // Dart codebase); change both together if the list changes.
  static const _timezones = [
    'UTC', 'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'Europe/London', 'Europe/Berlin', 'Asia/Karachi', 'Asia/Kolkata', 'Asia/Dubai', 'Australia/Sydney',
  ];

  final _formKey = GlobalKey<FormState>();
  final _repository = PublisherRepository();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _phoneController;
  late String _timezone;
  late bool _notifyNewCall;
  String? _existingLogoUrl;
  File? _newLogoFile;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Read once, in initState — not as field initializers (widget/context aren't guaranteed
    // assigned yet at that point), same discipline as edit_profile_screen.dart.
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _companyNameController = TextEditingController(text: user?.companyName);
    _phoneController = TextEditingController(text: user?.phone);
    _timezone = _timezones.contains(user?.timezone) ? user!.timezone : 'UTC';
    _notifyNewCall = user?.notifyNewCall ?? true;
    _existingLogoUrl = user?.companyLogoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    // Gallery only — no camera capture, so no CAMERA permission is needed for this feature.
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked != null) setState(() => _newLogoFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final User updated = await _repository.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        companyName: _companyNameController.text.trim(),
        phone: _phoneController.text.trim(),
        timezone: _timezone,
        notifyNewCall: _notifyNewCall,
        logoFile: _newLogoFile,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateCurrentUser(updated);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoPreview = _newLogoFile != null
        ? Image.file(_newLogoFile!, height: 72, fit: BoxFit.contain)
        : (_existingLogoUrl != null ? Image.network(_existingLogoUrl!, height: 72, fit: BoxFit.contain) : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Company')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (logoPreview != null) ...[Center(child: logoPreview), const SizedBox(height: 12)],
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickLogo,
              icon: const Icon(Icons.image_outlined),
              label: Text(_existingLogoUrl == null && _newLogoFile == null ? 'Add Company Logo' : 'Change Logo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required.' : null,
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email.' : null,
            ),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            DropdownButtonFormField<String>(
              // Uses `value:` (not `initialValue:`) for compatibility, same as the rest of this app.
              value: _timezone,
              decoration: const InputDecoration(labelText: 'Time Zone'),
              items: _timezones.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
              onChanged: (v) => setState(() => _timezone = v ?? _timezone),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email me when a new call comes in on my numbers'),
              value: _notifyNewCall,
              onChanged: (v) => setState(() => _notifyNewCall = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
