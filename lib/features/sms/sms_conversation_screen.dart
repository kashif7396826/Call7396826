import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sms_models.dart';
import 'sms_repository.dart';

class SmsConversationScreen extends StatefulWidget {
  final int contactId;
  final String contactName;
  const SmsConversationScreen({super.key, required this.contactId, required this.contactName});

  @override
  State<SmsConversationScreen> createState() => _SmsConversationScreenState();
}

class _SmsConversationScreenState extends State<SmsConversationScreen> {
  final _repository = SmsRepository();
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();
  List<SmsMessage>? _messages;
  String? _error;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await _repository.getConversation(widget.contactId);
      if (!mounted) return;
      setState(() {
        _messages = result.messages;
        _error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  /// Deliberately does NOT show an optimistic "sent" bubble before the real API confirms —
  /// this waits for the actual POST /sms/threads/:contactId to succeed (a real Twilio Messages
  /// API call server-side) and then reloads the real conversation, so what's on screen always
  /// reflects what actually happened, never a guess.
  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await _repository.sendMessage(widget.contactId, body);
      _bodyController.clear();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _sendError = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : _messages == null
                    ? const Center(child: CircularProgressIndicator())
                    : _messages!.isEmpty
                        ? const Center(child: Text('No messages yet — say hello.'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages!.length,
                            itemBuilder: (context, index) => _MessageBubble(message: _messages![index]),
                          ),
          ),
          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_sendError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Message', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SmsMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isOutbound = message.isOutbound;
    return Align(
      alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isOutbound ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.body, style: TextStyle(color: isOutbound ? Theme.of(context).colorScheme.onPrimary : null)),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isOutbound ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
