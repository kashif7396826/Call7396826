import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/realtime/socket_service.dart';
import '../calls/call_history_screen.dart';
import '../calls/call_provider.dart';
import '../calls/in_call_screen.dart';
import '../calls/voice_service.dart';
import '../campaigns/campaigns_screen.dart';
import '../contacts/contact_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_screen.dart';

/// The authenticated app shell — bottom-tab navigation plus the real-time Socket.IO
/// connection's lifetime (connects here, once, for as long as the user stays logged in;
/// AuthProvider's logout() flow is responsible for calling SocketService.instance.disconnect()
/// so a stale connection doesn't outlive the session).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  final _screens = const [
    DashboardScreen(),
    CallHistoryScreen(),
    ContactListScreen(),
    CampaignsScreen(),
    ReportsScreen(),
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
    WidgetsBinding.instance.addObserver(this);
    unawaited(_registerVoice());
  }

  /// Registers for incoming calls and makes any failure VISIBLE — a silent failure here was
  /// exactly why inbound calling was undiagnosable for days. Messages never include tokens.
  Future<void> _registerVoice() async {
    try {
      final identity = await VoiceService.instance.register();
      debugPrint('HomeShell: VoiceService.register() succeeded, identity=$identity');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!VoiceService.instance.phoneAccountEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 12),
          content: const Text('Turn on the CallDrag calling account so incoming calls can ring.'),
          action: SnackBarAction(label: 'ENABLE', onPressed: VoiceService.instance.openPhoneAccountSettings),
        ));
      }
    } catch (e, st) {
      debugPrint('HomeShell: VoiceService.register() failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incoming-call setup failed. Check your connection and reopen the app.')),
      );
    }
  }

  // Coming back from Android's Settings screen (after enabling the calling account) re-checks
  // it, so the user doesn't have to restart the app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !VoiceService.instance.phoneAccountEnabled) {
      unawaited(_registerVoice());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), selectedIcon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Campaigns'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
