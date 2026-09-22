import '../../core/network/api_client.dart';
import 'wallet.dart';

class WalletRepository {
  final _api = ApiClient.instance;

  /// A super_admin would need to pass ?clientId= (see walletController.js's resolveClientId) —
  /// not wired up in this app yet since there's no client-switcher UI for that role built.
  /// Every other role gets their own client's wallet automatically.
  Future<Wallet> getWallet() async {
    final response = await _api.get('/wallet');
    return Wallet.fromJson((response.data as Map<String, dynamic>)['wallet'] as Map<String, dynamic>);
  }

  Future<List<WalletTransaction>> getTransactions({int page = 1, int limit = 25}) async {
    final response = await _api.get('/wallet/transactions', query: {'page': page, 'limit': limit});
    final data = (response.data as Map<String, dynamic>)['transactions'] as List;
    return data.map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// GET /wallet/payment-config — the Square Application ID + Location ID needed to initialize
  /// InAppPayments (not secrets, see the backend route's own doc comment). Call before showing
  /// the top-up screen.
  Future<({String applicationId, String locationId})> getPaymentConfig() async {
    final response = await _api.get('/wallet/payment-config');
    final data = response.data as Map<String, dynamic>;
    return (applicationId: data['squareApplicationId'] as String, locationId: data['squareLocationId'] as String);
  }

  /// POST /wallet/topup — charges a real card via Square and credits the wallet only once
  /// Square confirms the payment COMPLETED (see walletController.js's topup()). [sourceId] and
  /// [verificationToken] come from a completed Square In-App Payments buyer-verification flow
  /// (see topup_screen.dart) — this repository never sees a raw card number, only Square's own
  /// opaque tokens.
  Future<double> topup({
    required double amount,
    String? sourceId,
    String? verificationToken,
    bool useSavedCard = false,
    bool saveCard = false,
  }) async {
    final response = await _api.post('/wallet/topup', data: {
      'amount': amount,
      if (sourceId != null) 'sourceId': sourceId,
      if (verificationToken != null) 'verificationToken': verificationToken,
      'useSavedCard': useSavedCard,
      'saveCard': saveCard,
    });
    // (response.data['newBalance'] as num).toDouble() — not a plain `as double` cast: JSON
    // numbers with no fractional part (e.g. a balance that lands on a whole dollar) decode as
    // Dart `int`, and `int as double` throws at runtime. Same reasoning as wallet.dart's
    // double.parse(json[...].toString()) pattern for every other money field in this app.
    return ((response.data as Map<String, dynamic>)['newBalance'] as num).toDouble();
  }
}
