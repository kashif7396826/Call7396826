import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'call_provider.dart';
import 'in_call_screen.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

const _kKeypadRows = [
  ['1', ''],
  ['2', 'ABC'],
  ['3', 'DEF'],
  ['4', 'GHI'],
  ['5', 'JKL'],
  ['6', 'MNO'],
  ['7', 'PQRS'],
  ['8', 'TUV'],
  ['9', 'WXYZ'],
  ['*', ''],
  ['0', '+'],
  ['#', ''],
];

class _DialerScreenState extends State<DialerScreen> {
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _append(String digit) {
    _numberController.text += digit;
    _numberController.selection = TextSelection.collapsed(offset: _numberController.text.length);
    setState(() {});
  }

  void _backspace() {
    final text = _numberController.text;
    if (text.isEmpty) return;
    _numberController.text = text.substring(0, text.length - 1);
    _numberController.selection = TextSelection.collapsed(offset: _numberController.text.length);
    setState(() {});
  }

  Future<void> _call(CallProvider calls) async {
    var number = _numberController.text.trim();
    if (number.isEmpty) return;
    // Same normalization as the web softphone's assets/js/softphone.js — real production calls
    // were reaching Twilio with a literal "00" international prefix instead of "+" (confirmed
    // via the live calls table), which fails to connect. Every native dialer does this same
    // normalization.
    if (number.startsWith('00')) {
      number = '+${number.substring(2)}';
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InCallScreen()));
    await calls.startCall(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialer')),
      body: SafeArea(
        child: Consumer<CallProvider>(
          builder: (context, calls, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '+1 555 000 0000',
                    filled: false,
                    border: InputBorder.none,
                    suffixIcon: _numberController.text.isEmpty
                        ? null
                        : IconButton(icon: const Icon(Icons.backspace_outlined, color: AppColors.textDim), onPressed: _backspace),
                  ),
                ),
                if (calls.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(calls.errorMessage!, style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [for (final key in _kKeypadRows) _KeypadButton(digit: key[0], letters: key[1], onTap: () => _append(key[0]))],
                  ),
                ),
                const SizedBox(height: 16),
                // Explicit heroTag — see contact_list_screen.dart's own FAB for why.
                DecoratedBox(
                  decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                  child: FloatingActionButton.large(
                    heroTag: 'dialerCallFab',
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    onPressed: () => _call(calls),
                    child: const Icon(Icons.call, color: AppColors.navyDeep),
                  ),
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

class _KeypadButton extends StatelessWidget {
  final String digit;
  final String letters;
  final VoidCallback onTap;
  const _KeypadButton({required this.digit, required this.letters, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navySurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.navyBorder)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(digit, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              if (letters.isNotEmpty)
                Text(letters, style: const TextStyle(color: AppColors.textDim, fontSize: 9, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}
