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

  // POST /wallet/topup is intentionally NOT wired up here yet — it needs the Square In-App
  // Payments SDK integrated natively (Android/iOS) to tokenize a real card client-side, the
  // same way the website uses Square's Web Payments SDK. That's a separate, real native
  // integration this pass doesn't include — see README.md's "What's NOT built yet".
}
