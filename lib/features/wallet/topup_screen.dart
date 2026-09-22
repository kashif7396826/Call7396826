import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart';
import '../auth/auth_provider.dart';
import 'wallet_repository.dart';

/// Real card tokenization via the official Square In-App Payments SDK
/// (square_in_app_payments — same package Square itself publishes, checked against its actual
/// GitHub source/docs, not just its README). Uses startCardEntryFlowWithBuyerVerification, not
/// the plainer startCardEntryFlow, because this account's Square integration already requires
/// SCA/3D-Secure buyer verification on the website (wallet/topup.php passes billingContact into
/// tokenize() for exactly this reason) — the mobile SDK's equivalent is this buyer-verification
/// flow, which returns a SEPARATE verification token alongside the card nonce (see
/// squareClient.js's squareCreatePayment() on the backend for where that token actually goes).
///
/// Card numbers never reach this app's own Dart code — Square's native card-entry UI collects
/// them directly and only ever hands back an opaque nonce/token, same PCI model as the
/// website's Web Payments SDK.
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _repository = WalletRepository();
  final _amountController = TextEditingController(text: '25.00');
  bool _initializing = true;
  bool _processing = false;
  String? _error;
  String? _successMessage;
  String? _locationId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final config = await _repository.getPaymentConfig();
      await InAppPayments.setSquareApplicationId(config.applicationId);
      _locationId = config.locationId;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _startPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 1) {
      setState(() => _error = 'Enter an amount of at least \$1.00.');
      return;
    }
    if (_locationId == null) {
      setState(() => _error = 'Payments are not configured.');
      return;
    }

    setState(() {
      _error = null;
      _successMessage = null;
      _processing = true;
    });

    final user = context.read<AuthProvider>().currentUser;

    try {
      final money = Money((b) => b
        ..amount = (amount * 100).round()
        ..currencyCode = 'USD');
      final contact = Contact((b) => b..givenName = user?.name ?? 'CallDrag Customer');

      await InAppPayments.startCardEntryFlowWithBuyerVerification(
        onBuyerVerificationSuccess: (result) => _onVerified(result, amount),
        onBuyerVerificationFailure: _onVerificationFailed,
        onCardEntryCancel: () {
          if (mounted) setState(() => _processing = false);
        },
        buyerAction: 'Charge',
        money: money,
        squareLocationId: _locationId!,
        contact: contact,
        collectPostalCode: true,
      );
    } catch (e) {
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _onVerified(BuyerVerificationDetails result, double amount) async {
    // The card-entry form is already closed by the native SDK at this point for the
    // buyer-verification flow (unlike plain startCardEntryFlow, completeCardEntry is NOT
    // needed/called here — see the plugin's own reference.md).
    try {
      final newBalance = await _repository.topup(
        amount: amount,
        sourceId: result.nonce,
        verificationToken: result.token,
      );
      if (!mounted) return;
      setState(() {
        _processing = false;
        _successMessage = 'Success — \$${amount.toStringAsFixed(2)} added. New balance: \$${newBalance.toStringAsFixed(2)}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }

  void _onVerificationFailed(ErrorInfo errorInfo) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _error = errorInfo.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Funds')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount to add (USD)', prefixText: '\$ '),
                    enabled: !_processing,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Card details are entered directly into Square\'s own secure payment form — they never pass through or get stored on this device.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (_processing || _locationId == null) ? null : _startPayment,
                    child: _processing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Funds'),
                  ),
                ],
              ),
            ),
    );
  }
}
