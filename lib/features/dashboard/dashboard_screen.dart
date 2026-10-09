import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/stat_card.dart';
import '../auth/auth_provider.dart';
import '../calls/call.dart';
import '../calls/call_repository.dart';
import '../calls/dialer_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/report.dart';
import '../reports/report_repository.dart';
import '../wallet/wallet.dart';
import '../wallet/wallet_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _callRepository = CallRepository();
  final _walletRepository = WalletRepository();
  final _reportRepository = ReportRepository();
  Wallet? _wallet;
  ReportSummary? _summary;
  List<Call> _recentCalls = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _walletRepository.getWallet(),
        _callRepository.list(limit: 5),
        _reportRepository.getSummary(range: '7days'),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _recentCalls = (results[1] as CallListResult).calls;
        _summary = results[2] as ReportSummary;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final currency = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_wallet != null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Wallet Balance', style: TextStyle(color: AppColors.navyDeep, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(currency.format(_wallet!.balance),
                              style: const TextStyle(color: AppColors.navyDeep, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text('This Week', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_summary != null) ...[
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
                        StatCard(icon: Icons.people_outline, value: NumberFormat.decimalPattern().format(_summary!.uniqueCallers), label: 'Unique Callers', color: AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Call Overview', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      decoration: BoxDecoration(color: AppColors.navySurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.navyBorder)),
                      height: 140,
                      child: _CallOverviewChart(daily: _summary!.daily),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Recent Calls', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_recentCalls.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('No calls yet.', style: TextStyle(color: AppColors.textDim)))
                  else
                    Container(
                      decoration: BoxDecoration(color: AppColors.navySurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.navyBorder)),
                      child: Column(
                        children: [
                          for (var i = 0; i < _recentCalls.length; i++) ...[
                            _RecentCallTile(call: _recentCalls[i]),
                            if (i != _recentCalls.length - 1) const Divider(height: 1, indent: 68),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
      // Explicit heroTag — see contact_list_screen.dart's own FAB for why (IndexedStack keeps
      // every tab's FAB mounted at once, all colliding on the shared default tag otherwise).
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: AppColors.gradient),
        child: FloatingActionButton.extended(
          heroTag: 'dashboardFab',
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DialerScreen())),
          icon: const Icon(Icons.dialpad, color: AppColors.navyDeep),
          label: const Text('New Call', style: TextStyle(color: AppColors.navyDeep, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _RecentCallTile extends StatelessWidget {
  final Call call;
  const _RecentCallTile({required this.call});

  bool get _isMissed => const ['no-answer', 'busy', 'failed', 'blocked', 'canceled'].contains(call.status);

  @override
  Widget build(BuildContext context) {
    final color = _isMissed ? AppColors.danger : AppColors.success;
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(call.direction == 'outbound' ? Icons.call_made : Icons.call_received, color: color, size: 18),
      ),
      title: Text(call.contactName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(call.status, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
    );
  }
}

class _CallOverviewChart extends StatelessWidget {
  final List<DailyCallCount> daily;
  const _CallOverviewChart({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Center(child: Text('No calls in this period.', style: TextStyle(color: AppColors.textDim)));
    }
    final maxY = daily.map((d) => d.calls).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.3,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.navySurfaceAlt,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem('${s.y.toInt()} calls', const TextStyle(color: AppColors.textPrimary, fontSize: 12)))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < daily.length; i++) FlSpot(i.toDouble(), daily[i].calls.toDouble())],
            isCurved: true,
            gradient: AppColors.gradient,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.cyan.withValues(alpha: 0.25), AppColors.cyan.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
