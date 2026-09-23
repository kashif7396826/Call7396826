import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'publisher_format.dart';
import 'publisher_models.dart';
import 'publisher_repository.dart';
import 'publisher_call_detail_screen.dart';

class PublisherDashboardScreen extends StatefulWidget {
  const PublisherDashboardScreen({super.key});

  @override
  State<PublisherDashboardScreen> createState() => _PublisherDashboardScreenState();
}

class _PublisherDashboardScreenState extends State<PublisherDashboardScreen> {
  final _repository = PublisherRepository();
  PublisherDashboard? _dashboard;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dashboard = await _repository.getDashboard();
      if (mounted) setState(() => _dashboard = dashboard);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('Hi, ${user?.name ?? ''}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _dashboard == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Overview of the numbers assigned to you.', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatCard(label: 'Assigned Numbers', value: '${_dashboard!.totalNumbers}'),
                          _StatCard(label: 'Active', value: '${_dashboard!.activeNumbers}'),
                          _StatCard(label: 'Inactive', value: '${_dashboard!.inactiveNumbers}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(label: 'Total Calls', value: '${_dashboard!.totalCalls}'),
                          _StatCard(label: 'Answered', value: '${_dashboard!.answeredCalls}', color: Colors.green),
                          _StatCard(label: 'Missed', value: '${_dashboard!.missedCalls}', color: Colors.red),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Recent Calls', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_dashboard!.recentCalls.isEmpty)
                        Text(
                          _dashboard!.totalNumbers == 0
                              ? 'No numbers have been assigned to you yet — contact your client administrator.'
                              : 'No calls yet.',
                        )
                      else
                        ..._dashboard!.recentCalls.map((call) => ListTile(
                              leading: Icon(call.direction == 'outbound' ? Icons.call_made : Icons.call_received),
                              title: Text(call.caller),
                              subtitle: Text('${call.publisherNumber} • ${call.statusLabel} • ${formatDuration(call.durationSeconds)}'),
                              trailing: Text(DateFormat.MMMd().add_jm().format(call.createdAt), style: const TextStyle(fontSize: 12)),
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => PublisherCallDetailScreen(call: call))),
                            )),
                    ],
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
