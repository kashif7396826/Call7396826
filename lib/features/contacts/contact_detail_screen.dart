import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contact.dart';
import 'contact_repository.dart';
import 'contact_form_screen.dart';
import '../calls/call_provider.dart';
import '../calls/in_call_screen.dart';
import '../sms/sms_conversation_screen.dart';

class ContactDetailScreen extends StatefulWidget {
  final int contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final _repository = ContactRepository();
  Contact? _contact;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final contact = await _repository.getOne(widget.contactId);
      if (mounted) setState(() => _contact = contact);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ContactFormScreen(contact: _contact)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text('This will permanently delete ${_contact?.fullName ?? 'this contact'}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.remove(widget.contactId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        actions: [
          IconButton(onPressed: _contact == null ? null : _edit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: _contact == null ? null : _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _contact == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_contact!.fullName, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Chip(label: Text(_contact!.stage)),
                    if (_contact!.onDncList) ...[
                      const SizedBox(height: 8),
                      const Chip(label: Text('On Do Not Call list'), backgroundColor: Colors.red),
                    ],
                    const SizedBox(height: 16),
                    ListTile(leading: const Icon(Icons.phone), title: Text(_contact!.phone)),
                    if (_contact!.email != null && _contact!.email!.isNotEmpty)
                      ListTile(leading: const Icon(Icons.email), title: Text(_contact!.email!)),
                    if (_contact!.company != null && _contact!.company!.isNotEmpty)
                      ListTile(leading: const Icon(Icons.business), title: Text(_contact!.company!)),
                    if (_contact!.notes != null && _contact!.notes!.isNotEmpty)
                      ListTile(leading: const Icon(Icons.notes), title: Text(_contact!.notes!)),
                    const SizedBox(height: 24),
                    if (!_contact!.onDncList)
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              // Same pattern as DialerScreen._call(): push the in-call UI, then
                              // drive it via the shared CallProvider, so a call started from a
                              // contact's own page behaves identically to one dialed manually.
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InCallScreen()));
                              await context.read<CallProvider>().startCall(_contact!.phone);
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => SmsConversationScreen(contactId: _contact!.id, contactName: _contact!.fullName),
                            )),
                            icon: const Icon(Icons.message_outlined),
                            label: const Text('Message'),
                          ),
                        ],
                      ),
                  ],
                ),
    );
  }
}
