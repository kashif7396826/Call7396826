import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sms_models.dart';
import 'sms_repository.dart';
import 'sms_conversation_screen.dart';

class SmsThreadsScreen extends StatefulWidget {
  const SmsThreadsScreen({super.key});

  @override
  State<SmsThreadsScreen> createState() => _SmsThreadsScreenState();
}

class _SmsThreadsScreenState extends State<SmsThreadsScreen> {
  final _repository = SmsRepository();
  List<SmsThread>? _threads;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final threads = await _repository.getThreads();
      if (mounted) setState(() => _threads = threads);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _threads == null
                ? const Center(child: CircularProgressIndicator())
                : _threads!.isEmpty
                    ? const Center(child: Text('No conversations yet.'))
                    : ListView.builder(
                        itemCount: _threads!.length,
                        itemBuilder: (context, index) {
                          final thread = _threads![index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(thread.contactName.isNotEmpty ? thread.contactName[0].toUpperCase() : '?'),
                            ),
                            title: Text(thread.contactName),
                            subtitle: Text(
                              '${thread.lastDirection == 'outbound' ? 'You: ' : ''}${thread.lastBody}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(DateFormat.MMMd().add_jm().format(thread.lastAt), style: const TextStyle(fontSize: 12)),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SmsConversationScreen(contactId: thread.contactId, contactName: thread.contactName)),
                              );
                              _load();
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
