import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'campaign.dart';
import 'campaign_repository.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final _repository = CampaignRepository();
  List<Campaign> _campaigns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final campaigns = await _repository.list();
      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
                : _campaigns.isEmpty
                    ? ListView(children: const [
                        Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No campaigns yet.', style: TextStyle(color: AppColors.textDim)))),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _campaigns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _CampaignCard(campaign: _campaigns[index]),
                      ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final rate = campaign.answerRate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(campaign.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (campaign.isActive ? AppColors.success : AppColors.textDim).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  campaign.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: campaign.isActive ? AppColors.success : AppColors.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (campaign.description != null && campaign.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(campaign.description!, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricPill(icon: Icons.people_outline, label: '${NumberFormat.decimalPattern().format(campaign.contactCount)} contacts'),
              const SizedBox(width: 8),
              _MetricPill(icon: Icons.call_outlined, label: '${NumberFormat.decimalPattern().format(campaign.callCount)} calls'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 6,
                    backgroundColor: AppColors.navySurfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                rate != null ? '${(rate * 100).toStringAsFixed(0)}%' : '—',
                style: const TextStyle(color: AppColors.cyan, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Answer rate', style: TextStyle(color: AppColors.textDim, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.navySurfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textDim),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
