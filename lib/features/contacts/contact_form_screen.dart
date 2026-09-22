import 'package:flutter/material.dart';
import 'contact.dart';
import 'contact_repository.dart';

/// Used for both create (pass no [contact]) and edit (pass the existing [contact]) — mirrors
/// how the backend's create/update endpoints share the same field set.
class ContactFormScreen extends StatefulWidget {
  final Contact? contact;
  const ContactFormScreen({super.key, this.contact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ContactRepository();
  // Created in initState(), not as field initializers — `widget` is not guaranteed to be
  // assigned yet when a State's own instance field initializers run, only from initState()
  // onward. Declaring these `late` and assigning them there avoids relying on that ordering.
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _company;
  late final TextEditingController _notes;
  late String _stage;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.contact?.firstName);
    _lastName = TextEditingController(text: widget.contact?.lastName);
    _phone = TextEditingController(text: widget.contact?.phone);
    _email = TextEditingController(text: widget.contact?.email);
    _company = TextEditingController(text: widget.contact?.company);
    _notes = TextEditingController(text: widget.contact?.notes);
    _stage = widget.contact?.stage ?? 'new';
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _phone, _email, _company, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await _repository.update(widget.contact!.id, {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'company': _company.text.trim(),
          'stage': _stage,
          'notes': _notes.text.trim(),
        });
      } else {
        await _repository.create(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          company: _company.text.trim(),
          stage: _stage,
          notes: _notes.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Guarded like the finally block below — calling setState() after this widget is
      // disposed (e.g. the user navigated back while the request was still in flight) throws.
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Contact' : 'New Contact')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name')),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            TextFormField(controller: _company, decoration: const InputDecoration(labelText: 'Company')),
            DropdownButtonFormField<String>(
              // Uses `value:` (not the newer `initialValue:`) for compatibility with the
              // Flutter >=3.22.0 floor this project declares in pubspec.yaml.
              value: _stage,
              decoration: const InputDecoration(labelText: 'Stage'),
              items: kContactStages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _stage = v ?? _stage),
            ),
            TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Create Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
