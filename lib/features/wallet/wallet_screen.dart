import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../invoices/invoice_list_screen.dart';
import 'wallet.dart';
import 'wallet_repository.dart';
import 'topup_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _repository = WalletRepository();
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_repository.getWallet(), _repository.getTransactions()]);
      setState(() {
        _wallet = results[0] as Wallet;
        _transactions = results[1] as List<WalletTransaction>;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openTopup() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TopupScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final user = context.watch<AuthProvider>().currentUser;
    // Matches the backend's own gate on POST /wallet/topup (client_admin/super_admin only —
    // requireRole in walletRoutes.js) — hiding the button for anyone else is a UX nicety, the
    // real enforcement is server-side regardless of what this app shows.
    final canTopup = user != null && (user.isClientAdmin || user.isSuperAdmin);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoiceListScreen())),
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Invoices',
          ),
          if (canTopup) IconButton(onPressed: _openTopup, icon: const Icon(Icons.add_card), tooltip: 'Add Funds'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _wallet == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Balance', style: TextStyle(color: Colors.grey)),
                              Text(
                                currency.format(_wallet!.balance),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: _wallet!.isLowBalance ? Colors.orange : null,
                                    ),
                              ),
                              if (_wallet!.isLowBalance) const Text('Low balance', style: TextStyle(color: Colors.orange)),
                              if (_wallet!.status != 'active')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('Account ${_wallet!.status}', style: const TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._transactions.map((tx) => ListTile(
                            leading: Icon(tx.amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline),
                            title: Text(tx.description ?? tx.type),
                            subtitle: Text(DateFormat.yMd().add_jm().format(tx.createdAt)),
                            trailing: Text(currency.format(tx.amount)),
                          )),
                    ],
                  ),
      ),
    );
  }
}
