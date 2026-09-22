import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'invoice.dart';
import 'invoice_repository.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _repository = InvoiceRepository();
  Invoice? _invoice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invoice = await _repository.getOne(widget.invoiceId);
      if (mounted) setState(() => _invoice = invoice);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(title: Text(_invoice?.invoiceNumber ?? 'Invoice')),
      body: _error != null
          ? Center(child: Text(_error!))
          : _invoice == null
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
                            Text('Total Amount', style: TextStyle(color: Colors.grey[600])),
                            Text(currency.format(_invoice!.totalAmount), style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Chip(label: Text(_invoice!.status)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Row('Period', '${DateFormat.yMd().format(_invoice!.periodStart)} – ${DateFormat.yMd().format(_invoice!.periodEnd)}'),
                    _Row('Total Calls', '${_invoice!.totalCalls}'),
                    _Row('Total Minutes', _invoice!.totalMinutes.toStringAsFixed(1)),
                    _Row('Call Charges', currency.format(_invoice!.callCharges)),
                    _Row('Recording Charges', currency.format(_invoice!.recordingCharges)),
                    if (_invoice!.credits != 0) _Row('Credits', currency.format(_invoice!.credits)),
                    _Row('Created', DateFormat.yMd().format(_invoice!.createdAt)),
                    if (_invoice!.paidAt != null) _Row('Paid', DateFormat.yMd().format(_invoice!.paidAt!)),
                  ],
                ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }
}
