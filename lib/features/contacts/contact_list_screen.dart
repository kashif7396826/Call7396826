import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'contact.dart';
import 'contact_repository.dart';
import 'contact_detail_screen.dart';
import 'contact_form_screen.dart';

const _kAvatarPalette = [AppColors.cyan, AppColors.success, AppColors.warning, Color(0xFFA78BFA), Color(0xFFF472B6), AppColors.blue];

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
        title: const Text('Contacts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search contacts…',
                prefixIcon: Icon(Icons.search, color: AppColors.textDim),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
                  : _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _contacts.isEmpty
                          ? const Center(child: Text('No contacts found.', style: TextStyle(color: AppColors.textDim)))
                          : ListView.separated(
                              itemCount: _contacts.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                              itemBuilder: (context, index) {
                                final contact = _contacts[index];
                                final color = _kAvatarPalette[contact.id % _kAvatarPalette.length];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: color.withValues(alpha: 0.18),
                                    child: Text(
                                      contact.firstName.isNotEmpty ? contact.firstName[0].toUpperCase() : '?',
                                      style: TextStyle(color: color, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  title: Text(contact.fullName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                  subtitle: Text(contact.phone, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
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
          ),
        ],
      ),
      // Explicit heroTag: home_shell.dart keeps every tab screen mounted at once via
      // IndexedStack (for instant tab switching), so every FAB on every tab is simultaneously
      // in the tree — without a unique tag they all collide on Flutter's shared default Hero
      // tag, a real crash confirmed against a live device 2026-09-27, not a rare edge case.
      floatingActionButton: FloatingActionButton(
        heroTag: 'contactListFab',
        onPressed: _createContact,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
