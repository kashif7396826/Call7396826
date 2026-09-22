import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'call_provider.dart';

class InCallScreen extends StatelessWidget {
  const InCallScreen({super.key});

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
            if (calls.state == ActiveCallState.ended) {
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
                  FloatingActionButton.large(
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
