import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'publisher_format.dart';
import 'publisher_models.dart';
import 'publisher_repository.dart';
import 'publisher_calls_screen.dart';

class PublisherNumbersScreen extends StatefulWidget {
  const PublisherNumbersScreen({super.key});

  @override
  State<PublisherNumbersScreen> createState() => _PublisherNumbersScreenState();
}

class _PublisherNumbersScreenState extends State<PublisherNumbersScreen> {
  final _repository = PublisherRepository();
  List<PublisherNumber>? _numbers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final numbers = await _repository.getNumbers();
      if (mounted) setState(() => _numbers = numbers);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Numbers')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _numbers == null
                ? const Center(child: CircularProgressIndicator())
                : _numbers!.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No numbers have been assigned to you yet — contact your client administrator.',
                          textAlign: TextAlign.center,
                        ),
                      ))
                    : ListView.builder(
                        itemCount: _numbers!.length,
                        itemBuilder: (context, index) {
                          final number = _numbers![index];
                          return ListTile(
                            leading: Icon(Icons.phone, color: number.isActive ? Colors.green : Colors.grey),
                            title: Text(number.phoneNumber),
                            subtitle: Text([
                              if (number.campaignName != null) number.campaignName!,
                              if (number.assignedAt != null) 'Assigned ${DateFormat.yMd().format(number.assignedAt!)}',
                            ].join(' • ')),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${number.stats.total} calls', style: const TextStyle(fontSize: 12)),
                                Text(formatDuration(number.stats.durationSeconds), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PublisherCallsScreen(numberId: number.id, numberLabel: number.phoneNumber)),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
