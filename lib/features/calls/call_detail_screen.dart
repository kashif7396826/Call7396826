import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'call.dart';
import 'call_repository.dart';
import 'recording_player.dart';

class CallDetailScreen extends StatefulWidget {
  final int callId;
  const CallDetailScreen({super.key, required this.callId});

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  final _repository = CallRepository();
  Call? _call;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final call = await _repository.getOne(widget.callId);
      setState(() => _call = call);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Only meaningful for a call still in progress — this REST snapshot doesn't know that on
  /// its own, so the button is offered whenever status suggests it might still be live rather
  /// than hidden entirely; the real Twilio REST call (controllers/callController.js's endCall)
  /// is the actual source of truth and will 409 cleanly if the call has already ended.
  bool get _mightBeLive => _call != null && !['completed', 'failed', 'busy', 'no-answer', 'blocked'].contains(_call!.status);

  Future<void> _endCall() async {
    try {
      await _repository.endCall(widget.callId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call ended.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Details')),
      body: _error != null
          ? Center(child: Text(_error!))
          : _call == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_call!.contactName, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _InfoRow('Direction', _call!.direction),
                    _InfoRow('Status', _call!.status),
                    _InfoRow('From', _call!.fromNumber),
                    _InfoRow('To', _call!.toNumber),
                    if (_call!.durationSeconds != null) _InfoRow('Duration', '${_call!.durationSeconds}s'),
                    _InfoRow('Provider', _call!.provider),
                    _InfoRow('Started', _call!.startedAt != null ? DateFormat.yMd().add_jms().format(_call!.startedAt!) : '—'),
                    const SizedBox(height: 24),
                    if (_call!.hasRecording) ...[
                      Text('Recording', style: Theme.of(context).textTheme.titleMedium),
                      RecordingPlayer(callId: _call!.id),
                      const SizedBox(height: 24),
                    ],
                    if (_mightBeLive)
                      FilledButton.icon(
                        onPressed: _endCall,
                        icon: const Icon(Icons.call_end),
                        label: const Text('End Call'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      ),
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
