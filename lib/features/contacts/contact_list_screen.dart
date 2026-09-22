import 'dart:async';
import 'package:flutter/material.dart';
import 'contact.dart';
import 'contact_repository.dart';
import 'contact_detail_screen.dart';
import 'contact_form_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final _repository = ContactRepository();
  final _searchController = TextEditingController();
  List<Contact> _contacts = [];
  String? _error;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final contacts = await _repository.list(search: _searchController.text.trim());
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _createContact() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const ContactFormScreen()));
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(hintText: 'Search contacts…', border: InputBorder.none),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? const Center(child: Text('No contacts found.'))
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(contact.firstName.isNotEmpty ? contact.firstName[0].toUpperCase() : '?')),
                            title: Text(contact.fullName),
                            subtitle: Text(contact.phone),
                            trailing: Chip(label: Text(contact.stage), visualDensity: VisualDensity.compact),
                            onTap: () async {
                              final changed = await Navigator.of(context)
                                  .push<bool>(MaterialPageRoute(builder: (_) => ContactDetailScreen(contactId: contact.id)));
                              if (changed == true) _load();
                            },
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _createContact, child: const Icon(Icons.person_add)),
    );
  }
}
