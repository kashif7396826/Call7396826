import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(title: const Text('Call History')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null
            ? Center(child: Text(_error!))
            : ListView.builder(
                itemCount: _calls.length + 1,
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

  IconData get _directionIcon => call.direction == 'outbound' ? Icons.call_made : Icons.call_received;

  @override
  Widget build(BuildContext context) {
    final duration = call.durationSeconds != null ? Duration(seconds: call.durationSeconds!) : null;
    return ListTile(
      leading: CircleAvatar(child: Icon(_directionIcon)),
      title: Text(call.contactName),
      subtitle: Text(
        [
          call.status,
          if (duration != null) '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          DateFormat.yMd().add_jm().format(call.createdAt),
        ].join(' • '),
      ),
      trailing: call.hasRecording ? const Icon(Icons.mic) : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallDetailScreen(callId: call.id))),
    );
  }
}
