import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/stat_card.dart';
import 'report.dart';
import 'report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repository = ReportRepository();
  String _range = '7days';
  ReportSummary? _summary;
  bool _loading = true;
  String? _error;

  static const _rangeLabels = {'today': 'Today', '7days': '7 Days', '30days': '30 Days'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await _repository.getSummary(range: _range);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectRange(String range) {
    if (range == _range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: _rangeLabels.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _range == e.key,
                          onSelected: (_) => _selectRange(e.key),
                          selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: _range == e.key ? AppColors.cyan : AppColors.textDim,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(color: _range == e.key ? AppColors.cyan : AppColors.navyBorder),
                          backgroundColor: AppColors.navySurfaceAlt,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))))
            else if (_summary != null) ...[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  StatCard(icon: Icons.call_outlined, value: NumberFormat.decimalPattern().format(_summary!.totalCalls), label: 'Total Calls', color: AppColors.cyan),
                  StatCard(icon: Icons.check_circle_outline, value: NumberFormat.decimalPattern().format(_summary!.answered), label: 'Answered', color: AppColors.success),
                  StatCard(icon: Icons.call_missed, value: NumberFormat.decimalPattern().format(_summary!.missed), label: 'Missed', color: AppColors.danger),
                  StatCard(icon: Icons.percent, value: '${(_summary!.answerRate * 100).toStringAsFixed(0)}%', label: 'Answer Rate', color: AppColors.warning),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Call Trend', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(height: 180, child: _CallTrendChart(daily: _summary!.daily)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CallTrendChart extends StatelessWidget {
  final List<DailyCallCount> daily;
  const _CallTrendChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Center(child: Text('No calls in this period.', style: TextStyle(color: AppColors.textDim)));
    }
    final maxY = daily.map((d) => d.calls).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= daily.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat.Md().format(daily[i].day), style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.navySurfaceAlt,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem('${rod.toY.toInt()} calls', const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ),
        ),
        barGroups: [
          for (var i = 0; i < daily.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: daily[i].calls.toDouble(),
                gradient: AppColors.gradient,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }
}
