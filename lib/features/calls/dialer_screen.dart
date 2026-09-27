import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'call_provider.dart';
import 'in_call_screen.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _call(CallProvider calls) async {
    final number = _numberController.text.trim();
    if (number.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InCallScreen()));
    await calls.startCall(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Consumer<CallProvider>(
            builder: (context, calls, _) => Column(
              children: [
                TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28),
                  decoration: const InputDecoration(hintText: '+1 555 000 0000', border: OutlineInputBorder()),
                ),
                if (calls.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(calls.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const Spacer(),
                // Explicit heroTag — see contact_list_screen.dart's own FAB for why.
                FloatingActionButton.large(
                  heroTag: 'dialerCallFab',
                  backgroundColor: Colors.green,
                  onPressed: () => _call(calls),
                  child: const Icon(Icons.call, color: Colors.white),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
