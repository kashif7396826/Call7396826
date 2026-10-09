import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'call.dart';
import 'call_repository.dart';
import 'call_detail_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final _repository = CallRepository();
  final _calls = <Call>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final result = await _repository.list(page: _page);
      if (!mounted) return;
      setState(() {
        _calls.addAll(result.calls);
        _hasMore = _page < result.pagination.totalPages;
        _page++;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _calls.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _calls.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  if (index == _calls.length) {
                    if (_hasMore) {
                      _loadMore();
                      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                    }
                    return const SizedBox.shrink();
                  }
                  final call = _calls[index];
                  return _CallTile(call: call);
                },
              ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final Call call;
  const _CallTile({required this.call});

  bool get _isMissed => const ['no-answer', 'busy', 'failed', 'blocked', 'canceled'].contains(call.status);

  IconData get _directionIcon {
    if (_isMissed) return call.direction == 'outbound' ? Icons.call_made : Icons.call_missed;
    return call.direction == 'outbound' ? Icons.call_made : Icons.call_received;
  }

  Color get _statusColor => _isMissed ? AppColors.danger : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final duration = call.durationSeconds != null ? Duration(seconds: call.durationSeconds!) : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: _statusColor.withValues(alpha: 0.15),
        child: Icon(_directionIcon, color: _statusColor, size: 20),
      ),
      title: Text(call.contactName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(
        [
          if (duration != null && duration.inSeconds > 0) '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          DateFormat.MMMd().add_jm().format(call.createdAt),
        ].join(' • '),
        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
      ),
      trailing: call.hasRecording ? const Icon(Icons.mic, color: AppColors.textDim, size: 18) : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallDetailScreen(callId: call.id))),
    );
  }
}
