import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'publisher_format.dart';
import 'publisher_models.dart';
import 'publisher_repository.dart';
import 'publisher_call_detail_screen.dart';

/// Shows every call across all this publisher's assigned numbers, or — when opened from
/// PublisherNumbersScreen — just one number's calls. No further pagination beyond the
/// backend's own 200-row cap (publisherRepository.js's getCalls(), matching
/// publisher/calls.php's own "showing the most recent 200" note) since this app never fetches
/// more than that single request already returns.
class PublisherCallsScreen extends StatefulWidget {
  final int? numberId;
  final String? numberLabel;
  const PublisherCallsScreen({super.key, this.numberId, this.numberLabel});

  @override
  State<PublisherCallsScreen> createState() => _PublisherCallsScreenState();
}

class _PublisherCallsScreenState extends State<PublisherCallsScreen> {
  final _repository = PublisherRepository();
  List<PublisherCall>? _calls;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final calls = await _repository.getCalls(numberId: widget.numberId);
      if (mounted) setState(() => _calls = calls);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.numberLabel ?? 'Call Records')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _calls == null
                ? const Center(child: CircularProgressIndicator())
                : _calls!.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            widget.numberId != null ? 'No calls yet for this number.' : 'No calls yet for your assigned numbers.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _calls!.length,
                        itemBuilder: (context, index) {
                          final call = _calls![index];
                          return ListTile(
                            leading: Icon(call.direction == 'outbound' ? Icons.call_made : Icons.call_received),
                            title: Text(call.caller),
                            subtitle: Text('${call.publisherNumber} • ${call.statusLabel} • ${formatDuration(call.durationSeconds)}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(DateFormat.MMMd().add_jm().format(call.createdAt), style: const TextStyle(fontSize: 12)),
                                if (call.hasRecording) const Icon(Icons.mic, size: 14, color: Colors.grey),
                              ],
                            ),
                            onTap: () =>
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PublisherCallDetailScreen(call: call))),
                          );
                        },
                      ),
      ),
    );
  }
}
