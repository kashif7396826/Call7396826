import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
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
                CircleAvatar(radius: 32, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                Text(user.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(user.role.replaceAll('_', ' '), style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                // Publisher accounts don't get this — settings/profile.php (the page these
                // endpoints mirror) is gated requireNonPublisher() server-side too, and this
                // app has no publisher role support at all yet (see README.md).
                if (!user.isPublisher) ...[
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                  ),
                  const SizedBox(height: 16),
                ],
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
