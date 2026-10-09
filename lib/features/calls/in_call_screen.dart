import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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

  DateTime? _connectedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _keypadOpen = false;

  void _maybeStartTimer(ActiveCallState state) {
    if (state == ActiveCallState.connected && _connectedAt == null) {
      _connectedAt = DateTime.now();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed = DateTime.now().difference(_connectedAt!));
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _statusLabel(ActiveCallState state) {
    switch (state) {
      case ActiveCallState.connecting:
        return 'Calling…';
      case ActiveCallState.ringing:
        return 'Ringing…';
      case ActiveCallState.connected:
        final m = _elapsed.inMinutes.toString().padLeft(2, '0');
        final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
      case ActiveCallState.ended:
        return 'Call ended';
      case ActiveCallState.idle:
        return '';
    }
  }

  String _initialFor(String? number) {
    if (number == null) return '#';
    final letters = number.replaceAll(RegExp(r'[^A-Za-z]'), '');
    return letters.isNotEmpty ? letters[0].toUpperCase() : '#';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: SafeArea(
        child: Consumer<CallProvider>(
          builder: (context, calls, _) {
            _maybeStartTimer(calls.state);
            if (calls.state == ActiveCallState.ended && !_popScheduled) {
              _popScheduled = true;
              // Give the "Call ended" label a moment to be visible before popping.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 900), () {
                  if (context.mounted) Navigator.of(context).pop();
                });
              });
            }
            final name = calls.activeNumber ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                    child: Center(
                      child: Text(_initialFor(calls.activeNumber),
                          style: const TextStyle(color: AppColors.navyDeep, fontSize: 40, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_statusLabel(calls.state), style: const TextStyle(color: AppColors.textDim, fontSize: 15)),
                  const Spacer(flex: 3),
                  if (_keypadOpen) ...[
                    _InCallKeypad(onDigit: calls.sendDigit),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallControlButton(
                        icon: calls.isMuted ? Icons.mic_off : Icons.mic,
                        label: 'Mute',
                        active: calls.isMuted,
                        onPressed: calls.toggleMute,
                      ),
                      _CallControlButton(
                        icon: Icons.dialpad,
                        label: 'Keypad',
                        active: _keypadOpen,
                        onPressed: () => setState(() => _keypadOpen = !_keypadOpen),
                      ),
                      _CallControlButton(
                        icon: calls.isOnSpeaker ? Icons.volume_up : Icons.volume_down,
                        label: 'Speaker',
                        active: calls.isOnSpeaker,
                        onPressed: calls.toggleSpeaker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // Explicit heroTag — see contact_list_screen.dart's own FAB for why. This
                  // screen is pushed (not IndexedStack-resident like the tabs), but the same
                  // collision happens transiently against whichever screen's FAB is still in
                  // the tree during the push transition (e.g. dialer_screen's own FAB).
                  FloatingActionButton.large(
                    heroTag: 'inCallHangupFab',
                    backgroundColor: AppColors.danger,
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
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _CallControlButton({required this.icon, required this.label, required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filled(
          iconSize: 26,
          style: IconButton.styleFrom(
            backgroundColor: active ? AppColors.cyan : AppColors.navySurfaceAlt,
            foregroundColor: active ? AppColors.navyDeep : AppColors.textPrimary,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
      ],
    );
  }
}

class _InCallKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  const _InCallKeypad({required this.onDigit});

  static const _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        for (final d in _digits)
          Material(
            color: AppColors.navySurfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onDigit(d),
              child: Center(child: Text(d, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))),
            ),
          ),
      ],
    );
  }
}
