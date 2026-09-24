import 'package:flutter/material.dart';
import 'publisher_repository.dart';

/// Same form/flow as features/profile/change_password_screen.dart, kept as its own screen
/// (rather than a shared/parametrized one) for the same reason this whole publisher/ directory
/// stays separate from the staff screens — it hits the publisher-only endpoint
/// (POST /publisher/me/password), not /users/me/password, which 403s for this role server-side.
class PublisherChangePasswordScreen extends StatefulWidget {
  const PublisherChangePasswordScreen({super.key});

  @override
  State<PublisherChangePasswordScreen> createState() => _PublisherChangePasswordScreenState();
}

class _PublisherChangePasswordScreenState extends State<PublisherChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PublisherRepository();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed.')));
      Navigator.of(context).pop();
    } catch (e) {
      // Includes the real INVALID_PASSWORD case from publisherController.js's bcrypt.compare()
      // against the actual stored hash — this message comes straight from the backend.
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Current Password'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _newController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'New Password'),
              validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters.' : null,
            ),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              validator: (v) => (v != _newController.text) ? 'Passwords do not match.' : null,
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
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
