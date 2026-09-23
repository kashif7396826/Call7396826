import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/realtime/socket_service.dart';
import '../calls/call_history_screen.dart';
import '../calls/call_provider.dart';
import '../calls/in_call_screen.dart';
import '../calls/voice_service.dart';
import '../contacts/contact_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../sms/sms_threads_screen.dart';
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
  final _screens = const [
    DashboardScreen(),
    CallHistoryScreen(),
    ContactListScreen(),
    SmsThreadsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  // Captured once in initState() rather than looked up again in dispose() — calling
  // context.read() from dispose() is unsafe (the element tree may already be torn down by
  // then) and provider's own docs warn against it.
  late final CallProvider _calls;

  @override
  void initState() {
    super.initState();
    SocketService.instance.connect(onCallEvent: _handleCallEvent, onSmsEvent: _handleSmsEvent);

    // Registers this device with Twilio as soon as the user is authenticated — not deferred
    // until the first outbound dial — so an inbound call (once Firebase/FCM is configured; a
    // real gap tracked in README.md, harmless no-op until then) can actually reach this device.
    _calls = context.read<CallProvider>();
    _calls.listenForIncomingCalls();
    _calls.onIncomingCallActive = () {
      if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InCallScreen()));
    };
    // Best-effort — a transient network hiccup at app startup shouldn't be an unhandled
    // exception; the dialer's own startCall() re-registers with a fresh token before placing
    // a call regardless, so a failure here just means inbound calls won't reach this device
    // until the next successful registration. Wrapped in its own try/catch (not
    // .catchError()) since register() returns Future<String> and a .catchError handler that
    // returns nothing would itself throw trying to complete a non-nullable String future.
    unawaited(() async {
      try {
        await VoiceService.instance.register();
      } catch (_) {}
    }());
  }

  @override
  void dispose() {
    _calls.onIncomingCallActive = null;
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

  /// Same "real event, simple SnackBar for now" treatment as _handleCallEvent — a real inbound
  /// SMS reported by webhooks/sms_inbound.php on the PHP side, pushed via
  /// src/realtime/callEvents.js's emitSmsEvent(). Doesn't auto-refresh the threads/conversation
  /// screens if they're open; pull-to-refresh picks it up, same as every other list in this app.
  void _handleSmsEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final body = event['body'] as String?;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New message${body != null ? ': $body' : ''}'), duration: const Duration(seconds: 2)),
    );
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
          NavigationDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
