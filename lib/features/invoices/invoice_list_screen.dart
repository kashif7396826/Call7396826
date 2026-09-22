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
  List<Invoice> _invoices = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final invoices = await _repository.list();
      setState(() {
        _invoices = invoices;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!))
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? const Center(child: Text('No invoices yet.'))
                    : ListView.builder(
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
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
