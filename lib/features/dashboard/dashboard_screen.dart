import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../calls/call.dart';
import '../calls/call_repository.dart';
import '../calls/dialer_screen.dart';
import '../wallet/wallet.dart';
import '../wallet/wallet_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _callRepository = CallRepository();
  final _walletRepository = WalletRepository();
  Wallet? _wallet;
  List<Call> _recentCalls = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_walletRepository.getWallet(), _callRepository.list(limit: 5)]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _recentCalls = (results[1] as CallListResult).calls;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final currency = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(title: Text('Hi, ${user?.name ?? ''}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_wallet != null)
                    Card(
                      child: ListTile(
                        title: const Text('Wallet Balance'),
                        trailing: Text(
                          currency.format(_wallet!.balance),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text('Recent Calls', style: Theme.of(context).textTheme.titleMedium),
                  ..._recentCalls.map((call) => ListTile(
                        leading: Icon(call.direction == 'outbound' ? Icons.call_made : Icons.call_received),
                        title: Text(call.contactName),
                        subtitle: Text(call.status),
                      )),
                  if (_recentCalls.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No calls yet.')),
                ],
              ),
      ),
      // Explicit heroTag — see contact_list_screen.dart's own FAB for why (IndexedStack keeps
      // every tab's FAB mounted at once, all colliding on the shared default tag otherwise).
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboardFab',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DialerScreen())),
        icon: const Icon(Icons.dialpad),
        label: const Text('New Call'),
      ),
    );
  }
}
