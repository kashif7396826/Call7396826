import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import 'publisher_calls_screen.dart';
import 'publisher_dashboard_screen.dart';
import 'publisher_numbers_screen.dart';

/// The publisher app shell — deliberately separate from home_shell.dart (the staff shell), not
/// a variant of it. A publisher is blocked server-side from every route the staff shell's tabs
/// use (contacts, wallet, live calling, Socket.IO real-time — all require requireNonPublisher())
/// so reusing that shell and hiding tabs would be actively misleading; this only ever shows the
/// narrower set of things a publisher can actually do.
class PublisherHomeShell extends StatefulWidget {
  const PublisherHomeShell({super.key});

  @override
  State<PublisherHomeShell> createState() => _PublisherHomeShellState();
}

class _PublisherHomeShellState extends State<PublisherHomeShell> {
  int _index = 0;
  final _screens = const [
    PublisherDashboardScreen(),
    PublisherNumbersScreen(),
    PublisherCallsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.phone_outlined), selectedIcon: Icon(Icons.phone), label: 'Numbers'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
