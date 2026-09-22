/// Mirrors invoiceRepository.js's SELECT_FIELDS field-for-field. Invoices are generated
/// server-side (invoices/generate.php, Super Admin only, manual — no cron creates these) — this
/// app is read-only, same as the Node API itself.
class Invoice {
  final int id;
  final int clientId;
  final String invoiceNumber;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalCalls;
  final double totalMinutes;
  final double callCharges;
  final double recordingCharges;
  final double credits;
  final double totalAmount;
  final String status; // e.g. draft | issued | paid
  final DateTime createdAt;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    required this.clientId,
    required this.invoiceNumber,
    required this.periodStart,
    required this.periodEnd,
    required this.totalCalls,
    required this.totalMinutes,
    required this.callCharges,
    required this.recordingCharges,
    required this.credits,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.paidAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as int,
        clientId: json['client_id'] as int,
        invoiceNumber: json['invoice_number'] as String,
        periodStart: DateTime.parse(json['period_start'] as String),
        periodEnd: DateTime.parse(json['period_end'] as String),
        totalCalls: json['total_calls'] as int? ?? 0,
        totalMinutes: double.parse((json['total_minutes'] ?? 0).toString()),
        callCharges: double.parse((json['call_charges'] ?? 0).toString()),
        recordingCharges: double.parse((json['recording_charges'] ?? 0).toString()),
        credits: double.parse((json['credits'] ?? 0).toString()),
        totalAmount: double.parse((json['total_amount'] ?? 0).toString()),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
      );
}
