import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../calls/call_history_screen.dart';
import '../publisher/publisher_change_password_screen.dart';
import '../publisher/publisher_edit_profile_screen.dart';
import '../sms/sms_threads_screen.dart';
import '../wallet/wallet_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.cyan.withValues(alpha: 0.18),
                      backgroundImage: user.companyLogoPath != null ? NetworkImage(user.companyLogoPath!) : null,
                      child: user.companyLogoPath == null
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.cyan, fontSize: 20, fontWeight: FontWeight.w700))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                          Text(user.email, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SettingsSection(children: [
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    label: user.isPublisher ? 'Profile & Company' : 'Edit Profile',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => user.isPublisher ? const PublisherEditProfileScreen() : const EditProfileScreen(),
                    )),
                  ),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => user.isPublisher ? const PublisherChangePasswordScreen() : const ChangePasswordScreen(),
                    )),
                  ),
                ]),
                if (!user.isPublisher) ...[
                  const SizedBox(height: 16),
                  _SettingsSection(children: [
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallet',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
                    ),
                    _SettingsTile(
                      icon: Icons.message_outlined,
                      label: 'Messages',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmsThreadsScreen())),
                    ),
                    _SettingsTile(
                      icon: Icons.history,
                      label: 'Call History',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CallHistoryScreen())),
                    ),
                  ]),
                ],
                const SizedBox(height: 24),
                _SettingsSection(children: [
                  _SettingsTile(
                    icon: Icons.logout,
                    label: 'Log Out',
                    color: AppColors.danger,
                    onTap: () => auth.logout(),
                  ),
                ]),
              ],
            ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;
  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navyBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textDim),
      title: Text(label, style: TextStyle(color: tileColor, fontWeight: FontWeight.w600)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: AppColors.textDim) : null,
      onTap: onTap,
    );
  }
}
