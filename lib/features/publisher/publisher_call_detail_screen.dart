import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../calls/recording_player.dart';
import 'publisher_format.dart';
import 'publisher_models.dart';
import 'publisher_repository.dart';

/// Read-only — a publisher has no live call control (end/transfer/hold/recording-pause), only
/// ever a historical record + recording playback. Takes the [PublisherCall] directly rather
/// than re-fetching by id — the calls list already has every field this screen shows, and
/// there's no separate GET /publisher/calls/:id endpoint on the backend (only the list and the
/// recording proxy — see publisherRoutes.js).
class PublisherCallDetailScreen extends StatelessWidget {
  final PublisherCall call;
  const PublisherCallDetailScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final repository = PublisherRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Call Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(call.caller, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          _Row('Number', call.publisherNumber),
          _Row('Client', call.companyName ?? '—'),
          _Row('Direction', call.direction),
          _Row('Status', call.statusLabel),
          _Row('Duration', formatDuration(call.durationSeconds)),
          _Row('Date', DateFormat.yMd().add_jms().format(call.createdAt)),
          _Row('From', call.fromNumber),
          _Row('To', call.toNumber),
          if (call.hasRecording) ...[
            const SizedBox(height: 24),
            Text('Recording', style: Theme.of(context).textTheme.titleMedium),
            RecordingPlayer(path: repository.recordingUrl(call.id)),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
