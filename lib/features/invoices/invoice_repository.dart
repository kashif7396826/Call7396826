import '../../core/network/api_client.dart';
import '../calls/call.dart' show Pagination;
import 'invoice.dart';

class InvoiceRepository {
  final _api = ApiClient.instance;

  Future<InvoiceListResult> list({int page = 1, int limit = 25}) async {
    final response = await _api.get('/invoices', query: {'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final invoices = (data['invoices'] as List).map((i) => Invoice.fromJson(i as Map<String, dynamic>)).toList();
    return InvoiceListResult(invoices, Pagination.fromJson(data['pagination'] as Map<String, dynamic>));
  }

  Future<Invoice> getOne(int id) async {
    final response = await _api.get('/invoices/$id');
    return Invoice.fromJson((response.data as Map<String, dynamic>)['invoice'] as Map<String, dynamic>);
  }
}
