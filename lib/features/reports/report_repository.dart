import '../../core/network/api_client.dart';
import 'report.dart';

class ReportRepository {
  final _api = ApiClient.instance;

  /// [range] is one of 'today' | '7days' | '30days' — matches reportController.js's RANGE_DAYS.
  Future<ReportSummary> getSummary({String range = '7days'}) async {
    final response = await _api.get('/reports/summary', query: {'range': range});
    return ReportSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
