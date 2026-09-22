# CallDrag Mobile (Flutter)

Real mobile client for the CallDrag call-tracking CRM, talking to the live Node.js API at
**api.calldrag.com** (`/home/zsziykvi/api.calldrag.com` on the host, a separate project from
this one) — which itself reads/writes the same production MySQL database as the PHP web app at
**test11.dataposting.online**. No mock data, no fake screens, no simulated calling anywhere in
this codebase, per this project's explicit no-mock policy.

## ⚠️ This code has never been built or run

It was written on a shared cPanel hosting account that has **no Flutter SDK, no Android SDK, no
emulator, and no way to install one** — the same server that hosts the live PHP site and the
Node API. Every line here is unverified: no `flutter analyze`, no `flutter pub get`, no build,
no test. This is a real departure from how every other part of this project was built — every
PHP change got `php -l`'d, every Node change got `node --check`'d and exercised against the
live database with `supertest`, every webhook got a real signed request. None of that discipline
was possible here.

**Before trusting any of this:** open the project in a real Flutter environment (Android
Studio, VS Code + Flutter extension, or a CI runner) and actually build it. Expect to fix
compile errors — package APIs (especially `twilio_voice`, a community plugin) can differ subtly
by version from what's assumed here, even though the API calls in this code were checked
against that package's real source on GitHub (not just its README, which is stale in places —
see the comment in `lib/features/calls/voice_service.dart`).

## Setup

```bash
# 1. Get Flutter: https://docs.flutter.dev/get-started/install
flutter doctor

# 2. Generate the platform scaffolding this repo doesn't include (android/, ios/, etc.) —
#    this creates a fresh, CURRENT, version-matched Android/iOS project for whatever Flutter
#    version you have installed, which is safer than anything hand-written against an unknown
#    future Flutter version would be. It will NOT overwrite lib/, pubspec.yaml, or the one
#    hand-written Android file this repo does include (see below) — flutter create only fills
#    in files that don't already exist.
cd calldrag_mobile
flutter create --org com.calldrag --project-name calldrag_mobile .

# 3. Install dependencies
flutter pub get

# 4. Apply the manifest/permission additions below, then run
flutter run
```

### Android manifest additions (apply after step 2 above)

Add to `android/app/src/main/AndroidManifest.xml`, inside `<application ...>`:

```xml
<!-- Points at the network_security_config.xml this repo already includes, needed for
     just_audio's localhost header-proxy (see recording_player.dart). -->
android:networkSecurityConfig="@xml/network_security_config"
```

(If/when inbound calling is built — see below — a `<service>` block for
`com.twilio.twilio_voice.fcm.VoiceFirebaseMessagingService` also needs to go here. Not added
yet since it requires a real Firebase project this app doesn't have.)

## Pointing at a real backend for local development

`lib/core/config/api_config.dart` defaults to `https://api.calldrag.com/api/v1` — the real
production API. **As of 2026-09-22 that endpoint is not yet publicly reachable** (a pending
LiteSpeed routing issue on that host — see `api.calldrag.com`'s own git history / the PHP
project's `CLAUDE.md`), so login will fail against it until that's resolved.

For local development against a Node server running on your own machine:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1  # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:4000/api/v1  # iOS simulator / web
```

## What's real and built

- **Auth** — real login against `POST /auth/login`, real 2FA (`/auth/login/verify-totp`) for
  any account with TOTP enabled (same algorithm as the website, not skipped for mobile), real
  token refresh with rotation-on-use, tokens in the platform keystore
  (`flutter_secure_storage`), never `SharedPreferences`.
- **Dashboard, call history, call detail, wallet** — all real data from
  `GET /calls`, `GET /calls/:id`, `GET /wallet`, `GET /wallet/transactions`.
- **Recording playback** — streams the real, authenticated, server-proxied audio from
  `GET /calls/:id/recording` (never a raw Twilio/Telnyx URL — same rule as `recordings/play.php`
  on the PHP side).
- **Live call control** — `POST /calls/:id/end` and `/transfer` wired up from the call detail
  screen, plus `/recording/pause`, `/resume`, `/stop`.
- **Contacts** — full real CRUD against `/contacts` (list with search, create, edit, delete),
  including a "Call" button that starts a real outbound call to that contact.
- **Outbound calling** — real Twilio Voice SDK integration (`twilio_voice` plugin) against
  `GET /calls/incoming/token` for the access token and the real outbound TwiML webhook
  server-side. **Will not actually connect a call yet** — see the TwiML App repoint note below.
- **Real-time call events** — a real Socket.IO connection (`core/realtime/socket_service.dart`)
  to the same server that pushes `call:event` messages from `src/realtime/callEvents.js`.

## What's NOT built yet (real gaps, not silently skipped)

- **Inbound calling.** Twilio's Voice SDK delivers incoming-call notifications via Firebase
  Cloud Messaging on Android. This needs a real Firebase project (`google-services.json`,
  `VoiceFirebaseMessagingService` registered in the manifest) that doesn't exist for this app
  yet — a genuine credential/setup gap, not something to fake. `voice_service.dart` only
  registers for outbound calling.
- **Wallet top-up.** `POST /wallet/topup` exists and is real on the backend, but charging a
  card from this app needs the Square **In-App Payments SDK** integrated natively — a separate,
  real native integration this pass didn't include. `wallet_repository.dart` deliberately has no
  `topup()` method yet.
- **Hold.** No backend support at all yet — see the PHP/Node project's own notes on why (needs
  a Twilio Conference redesign).
- **The live TwiML App repoint.** The Voice Request URL Twilio actually calls for outbound
  calls still points at the PHP webhook (`webhooks/twiml_voice.php`), not the Node one this app
  and the browser softphone are meant to share. This is a deliberate, already-discussed decision
  to defer until `api.calldrag.com` is confirmed publicly reachable — flipping it early would
  break the currently-working browser softphone. Until it happens, outbound calls placed from
  this app will reach Twilio but the TwiML response will come from the old PHP path.
- **Publisher role.** Backend intentionally excludes publishers from most of this API
  (`requireNonPublisher()`) — this app doesn't have a publisher-specific view either.

## Architecture

```
lib/
  core/
    config/       — API base URL (overridable via --dart-define)
    network/      — Dio-based ApiClient with JWT auth + auto-refresh-on-401
    storage/      — Secure token storage
    realtime/     — Socket.IO client
  features/
    auth/         — login, TOTP, session state (Provider)
    dashboard/    — wallet summary + recent calls
    calls/        — call history/detail, recording playback, outbound calling (Twilio Voice SDK)
    contacts/     — list/search, create, edit, delete, call
    wallet/       — balance + transaction ledger (read-only for now)
    profile/      — current user + logout
    home/         — authenticated app shell (bottom nav + Socket.IO connection lifetime)
```

State management is `provider` (ChangeNotifier) — chosen for its small footprint and directness
given how few screens this app has so far; nothing here depends on it deeply enough that
switching to Riverpod later would be painful if that ever matters.
