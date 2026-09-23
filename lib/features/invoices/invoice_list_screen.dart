import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice.dart';
import 'invoice_repository.dart';
import 'invoice_detail_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _repository = InvoiceRepository();
  final _invoices = <Invoice>[];
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
        _invoices.addAll(result.invoices);
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
      _invoices.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null
            ? Center(child: Text(_error!))
            : _invoices.isEmpty && !_hasMore
                ? const Center(child: Text('No invoices yet.'))
                : ListView.builder(
                    itemCount: _invoices.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _invoices.length) {
                        if (_hasMore) {
                          _loadMore();
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        return const SizedBox.shrink();
                      }
                      final invoice = _invoices[index];
                      return ListTile(
                        title: Text(invoice.invoiceNumber),
                        subtitle: Text(
                          '${DateFormat.yMd().format(invoice.periodStart)} – ${DateFormat.yMd().format(invoice.periodEnd)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(invoice.totalAmount)),
                            Text(invoice.status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id))),
                      );
                    },
                  ),
      ),
    );
  }
}
