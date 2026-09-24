import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../publisher/publisher_change_password_screen.dart';
import '../publisher/publisher_edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user.companyLogoPath != null ? NetworkImage(user.companyLogoPath!) : null,
                  child: user.companyLogoPath == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?') : null,
                ),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                Text(user.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(user.role.replaceAll('_', ' '), style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                // Same two actions for every role — just routed at two different endpoint sets
                // server-side (staff hits /users/me, gated requireNonPublisher(); a publisher
                // hits /publisher/me, the inverse gate) since a publisher's profile has a
                // richer field set (company name/logo, phone, timezone, notify prefs) that
                // settings/profile.php's staff page doesn't have.
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(user.isPublisher ? 'Profile & Company' : 'Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => user.isPublisher ? const PublisherEditProfileScreen() : const EditProfileScreen(),
                  )),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => user.isPublisher ? const PublisherChangePasswordScreen() : const ChangePasswordScreen(),
                  )),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ],
            ),
    );
  }
}
