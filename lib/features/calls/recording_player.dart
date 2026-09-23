import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/config/api_config.dart';
import '../../core/storage/token_storage.dart';

/// Plays the real recording audio streamed from an authenticated, server-proxied endpoint
/// (controllers/callController.js's getRecording for staff, or
/// controllers/publisherController.js's getRecording for a publisher — mirroring
/// recordings/play.php either way) that never hands out a raw Twilio/Telnyx URL. The
/// Authorization header is attached exactly like every other API call, via just_audio's own
/// headers support (see its README's "Working with headers" — uses a local proxy under the
/// hood, which is why android/app/src/main/res/xml/network_security_config.xml allowlists
/// 127.0.0.1 for cleartext).
class RecordingPlayer extends StatefulWidget {
  /// The API path to stream from, e.g. `/calls/123/recording` or
  /// `/publisher/calls/123/recording` — callers pass CallRepository.recordingUrl(id) or
  /// PublisherRepository.recordingUrl(id) rather than building this themselves.
  final String path;
  const RecordingPlayer({super.key, required this.path});

  @override
  State<RecordingPlayer> createState() => _RecordingPlayerState();
}

class _RecordingPlayerState extends State<RecordingPlayer> {
  final _player = AudioPlayer();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await TokenStorage.instance.accessToken;
      final url = '${ApiConfig.baseUrl}${widget.path}';
      await _player.setUrl(url, headers: {if (token != null) 'Authorization': 'Bearer $token'});
    } catch (e) {
      _error = 'Could not load recording: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
    if (_error != null) return Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)));

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          children: [
            IconButton(
              iconSize: 40,
              icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
              onPressed: playing ? _player.pause : _player.play,
            ),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnapshot) {
                  final position = posSnapshot.data ?? Duration.zero;
                  final total = _player.duration ?? Duration.zero;
                  return Slider(
                    value: position.inMilliseconds.clamp(0, total.inMilliseconds > 0 ? total.inMilliseconds : 1).toDouble(),
                    max: total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1,
                    onChanged: (value) => _player.seek(Duration(milliseconds: value.toInt())),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
