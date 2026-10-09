/// Mirrors reportController.js's GET /reports/summary response — real call-volume totals for
/// the requested date range, plus a daily-count series for the trend chart.
class ReportSummary {
  final String range;
  final DateTime start;
  final DateTime end;
  final int totalCalls;
  final int answered;
  final int missed;
  final int uniqueCallers;
  final double answerRate;
  final List<DailyCallCount> daily;

  ReportSummary({
    required this.range,
    required this.start,
    required this.end,
    required this.totalCalls,
    required this.answered,
    required this.missed,
    required this.uniqueCallers,
    required this.answerRate,
    required this.daily,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return ReportSummary(
      range: json['range'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      totalCalls: totals['totalCalls'] as int,
      answered: totals['answered'] as int,
      missed: totals['missed'] as int,
      uniqueCallers: totals['uniqueCallers'] as int,
      answerRate: (totals['answerRate'] as num).toDouble(),
      daily: (json['daily'] as List).map((d) => DailyCallCount.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class DailyCallCount {
  final DateTime day;
  final int calls;
  DailyCallCount({required this.day, required this.calls});

  factory DailyCallCount.fromJson(Map<String, dynamic> json) =>
      DailyCallCount(day: DateTime.parse(json['day'] as String), calls: json['calls'] as int);
}
