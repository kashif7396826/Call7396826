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
  final _transactions = <WalletTransaction>[];
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final results = await Future.wait([_repository.getWallet(), _repository.getTransactions(page: 1)]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _transactions
          ..clear()
          ..addAll(results[1] as List<WalletTransaction>);
        _page = 1;
        // getTransactions() doesn't return the total pagination count (see wallet_repository.dart —
        // it hands back just the list), so "more might exist" is inferred from a full page coming
        // back, same convention as the rest of this app's infinite-scroll lists.
        _hasMore = (results[1] as List<WalletTransaction>).length == 25;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _repository.getTransactions(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _transactions.addAll(next);
        _page++;
        _hasMore = next.length == 25;
      });
    } catch (_) {
      // A failed "load more" shouldn't blank out the page the user is already looking at —
      // leave _hasMore as-is so pulling to refresh or scrolling again can retry.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openTopup() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TopupScreen()));
    _loadInitial();
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
        onRefresh: _loadInitial,
        child: _error != null
            ? Center(child: Text(_error!))
            : _wallet == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    // +2: the balance card and the "Recent Transactions" heading both live at
                    // fixed indices before the transaction list itself.
                    itemCount: _transactions.length + 3,
                    itemBuilder: (context, index) {
                      if (index == 0) return _BalanceCard(wallet: _wallet!, currency: currency);
                      if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
                        );
                      }
                      final txIndex = index - 2;
                      if (txIndex == _transactions.length) {
                        if (_hasMore) {
                          _loadMoreTransactions();
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        if (_transactions.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(16), child: Text('No transactions yet.'));
                        }
                        return const SizedBox.shrink();
                      }
                      final tx = _transactions[txIndex];
                      return ListTile(
                        leading: Icon(tx.amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline),
                        title: Text(tx.description ?? tx.type),
                        subtitle: Text(DateFormat.yMd().add_jm().format(tx.createdAt)),
                        trailing: Text(currency.format(tx.amount)),
                      );
                    },
                  ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Wallet wallet;
  final NumberFormat currency;
  const _BalanceCard({required this.wallet, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balance', style: TextStyle(color: Colors.grey)),
            Text(
              currency.format(wallet.balance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: wallet.isLowBalance ? Colors.orange : null),
            ),
            if (wallet.isLowBalance) const Text('Low balance', style: TextStyle(color: Colors.orange)),
            if (wallet.status != 'active')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Account ${wallet.status}', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
