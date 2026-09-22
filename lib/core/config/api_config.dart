/// Central endpoint configuration. Points at the REAL CallDrag Node API — never a mock server.
///
/// IMPORTANT (as of 2026-09-22): the live TwiML App's Voice Request URL still points at the
/// PHP webhook, not this API — see webhooks/twilio_voice.php / test11.dataposting.online's
/// CLAUDE.md history. Outbound calling from this app will not work end-to-end until that
/// repoint happens (it's deliberately deferred until api.calldrag.com is confirmed publicly
/// reachable — currently blocked on a LiteSpeed routing issue on that host). Everything else
/// (auth, contacts, calls list, wallet, recording playback, live call control) already works
/// once this app can reach the API at all.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the real backend. Change via `--dart-define=API_BASE_URL=...` for local dev
  /// (e.g. `http://10.0.2.2:4000/api/v1` for the Android emulator talking to a Node server
  /// running on your dev machine) — never hardcode a second copy of this elsewhere.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.calldrag.com/api/v1',
  );

  /// Socket.IO connects to the origin (no /api/v1 suffix — Socket.IO has its own path).
  static String get socketUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }
}
