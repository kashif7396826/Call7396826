import 'package:flutter/material.dart';
import '../../core/realtime/socket_service.dart';
import '../calls/call_history_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';

/// The authenticated app shell — bottom-tab navigation plus the real-time Socket.IO
/// connection's lifetime (connects here, once, for as long as the user stays logged in;
/// AuthProvider's logout() flow is responsible for calling SocketService.instance.disconnect()
/// so a stale connection doesn't outlive the session).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _screens = const [DashboardScreen(), CallHistoryScreen(), WalletScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    SocketService.instance.connect(onCallEvent: _handleCallEvent);
  }

  @override
  void dispose() {
    SocketService.instance.disconnect();
    super.dispose();
  }

  /// A real event pushed from the server (src/realtime/callEvents.js) — not a simulated
  /// notification. Kept intentionally simple for this first pass (a SnackBar); a richer
  /// per-screen live-refresh wiring (e.g. a ChangeNotifier the call history screen subscribes
  /// to) is real, worthwhile follow-up work, not built yet.
  void _handleCallEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = event['type'] as String? ?? 'call.event';
    final status = event['status'] as String?;
    final message = switch (type) {
      'call.status' => 'Call ${status ?? 'updated'}',
      'call.transferred' => 'Call transferred',
      'call.recording_paused' => 'Recording paused',
      'call.recording_resumed' => 'Recording resumed',
      'call.recording_stopped' => 'Recording stopped',
      _ => type,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
