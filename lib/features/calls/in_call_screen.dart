import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'call_provider.dart';

class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  // Consumer's builder re-runs on every notifyListeners() call while state stays `ended`
  // during the ~900ms delay below (e.g. isMuted/isOnSpeaker changing) — without this guard,
  // each rebuild would schedule ANOTHER delayed pop, and firing more than one could pop
  // whatever screen the user navigated to after this one was already dismissed.
  bool _popScheduled = false;

  String _statusLabel(ActiveCallState state) {
    switch (state) {
      case ActiveCallState.connecting:
        return 'Calling…';
      case ActiveCallState.ringing:
        return 'Ringing…';
      case ActiveCallState.connected:
        return 'Connected';
      case ActiveCallState.ended:
        return 'Call ended';
      case ActiveCallState.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<CallProvider>(
          builder: (context, calls, _) {
            if (calls.state == ActiveCallState.ended && !_popScheduled) {
              _popScheduled = true;
              // Give the "Call ended" label a moment to be visible before popping.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 900), () {
                  if (context.mounted) Navigator.of(context).pop();
                });
              });
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    calls.activeNumber ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(_statusLabel(calls.state), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControlButton(
                        icon: calls.isMuted ? Icons.mic_off : Icons.mic,
                        active: calls.isMuted,
                        onPressed: calls.toggleMute,
                      ),
                      _CallControlButton(
                        icon: calls.isOnSpeaker ? Icons.volume_up : Icons.volume_down,
                        active: calls.isOnSpeaker,
                        onPressed: calls.toggleSpeaker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Explicit heroTag — see contact_list_screen.dart's own FAB for why. This
                  // screen is pushed (not IndexedStack-resident like the tabs), but the same
                  // collision happens transiently against whichever screen's FAB is still in
                  // the tree during the push transition (e.g. dialer_screen's own FAB).
                  FloatingActionButton.large(
                    heroTag: 'inCallHangupFab',
                    backgroundColor: Colors.red,
                    onPressed: calls.hangUp,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  const _CallControlButton({required this.icon, required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          iconSize: 28,
          style: IconButton.styleFrom(
            backgroundColor: active ? Colors.white : Colors.white24,
            foregroundColor: active ? Colors.black : Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      ],
    );
  }
}
