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

For inbound calling (see "Inbound calling setup" below), also add, inside `<application ...>`:

```xml
<service android:name="com.twilio.twilio_voice.fcm.VoiceFirebaseMessagingService"
    android:exported="false"
    android:stopWithTask="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### Android minSdkVersion

`square_in_app_payments` (the official Square SDK, used for wallet top-up) requires
**`minSdkVersion 28`** (Android 9) — higher than Flutter's own template default. After running
`flutter create` (step 2 above), open `android/app/build.gradle` (or `build.gradle.kts`) and
raise `minSdkVersion`/`minSdk` to `28` if it isn't already. `twilio_voice` doesn't impose a
higher floor than this.

## Inbound calling setup

All the code for this is already in place (`voice_service.dart` requests a device token and
wires up token refresh, `call_provider.dart` recognizes an inbound call via
`TwilioCallPlatform.activeCall` and tells `home_shell.dart` to navigate into the in-call screen,
`main.dart` initializes Firebase). What's genuinely missing is a real Firebase project — this
repo can't create one on your behalf (no AI agent should be creating third-party accounts for
you). Until you do this, the app runs completely normally; `main.dart`'s Firebase.initializeApp()
just fails against the placeholder config in `firebase_options.dart` and gets caught, so only
inbound calling is unavailable — everything else in this app is unaffected.

1. Create a project at [Firebase Console](https://console.firebase.google.com).
2. Add an Android app to it with the applicationId `flutter create` gave this project (default:
   `com.calldrag.calldrag_mobile`, from step 2's `--org com.calldrag` above).
3. Install the CLI (`dart pub global activate flutterfire_cli`) and run
   `flutterfire configure` from this project's root, selecting the project/app you just made.
   This OVERWRITES `lib/firebase_options.dart` with your real values (see that file's own doc
   comment) and places `google-services.json` under `android/app/` — already gitignored, never
   commit it.
4. Add the `<service>` block above to `AndroidManifest.xml`.
5. In [Twilio Console](https://console.twilio.com) → Voice → Manage → Push Credentials, create
   an Android (FCM) push credential using the Firebase project's **Server key**
   (Firebase Console → Project Settings → Cloud Messaging → legacy API, or a service account
   under the newer HTTP v1 API — twilio_voice's own troubleshooting doc covers both). This is
   what actually lets Twilio deliver a ringing notification to a real device — without it,
   Twilio has a device token but nowhere to send the push.
6. Rebuild and run. A real inbound call to this agent's Twilio identity should now ring the
   device via Android's native ConnectionService UI (or iOS CallKit) — this app never draws its
   own incoming-call screen; it only shows `InCallScreen` reactively once the native UI answers.

## Pointing at a real backend for local development

`lib/core/config/api_config.dart` defaults to `https://api.calldrag.com/api/v1` — the real
production API. **As of 2026-09-22, the app itself is live and responding correctly there**
(verified with a real authenticated request) — the one remaining blocker is that
`api.calldrag.com` still serves the hosting account's default shared SSL certificate instead of
a real one for that domain, so any client that correctly verifies the hostname (this app
included) will refuse the connection until a real certificate is issued. That's a host-level
permission gap (AutoSSL isn't enabled for this account), not something fixable from this
project's code.

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
- **Invoices** — real, read-only data from `/invoices` (server-generated, Super Admin only via
  the website — this app just lists/views them), linked from the Wallet screen.
- **Edit Profile / Change Password** — real `PATCH /users/me` and `POST /users/me/password`
  (already verified server-side against a real account before this UI existed — see the
  Node API's own commit history). Not shown for publisher accounts, matching the backend's own
  `requireNonPublisher()` gate on these endpoints.
- **Outbound and inbound calling** — real Twilio Voice SDK integration (`twilio_voice`
  plugin). Outbound: `GET /calls/incoming/token` for the access token, the real outbound TwiML
  webhook server-side. Inbound: FCM device-token registration with token-refresh handling,
  Android calling-account/permission setup, and `activeCall`-based direction detection so
  `home_shell.dart` navigates into the in-call screen reactively when a call answered via the
  native ConnectionService/CallKit UI becomes active — this app never draws its own
  incoming-call screen. Both need a real Firebase project to actually test inbound (see
  "Inbound calling setup" above) — the code doesn't fake that in the meantime, it degrades to
  outbound-only. **Will not actually connect a call yet regardless** — see the TwiML App
  repoint note below.
- **Real-time call events** — a real Socket.IO connection (`core/realtime/socket_service.dart`)
  to the same server that pushes `call:event` messages from `src/realtime/callEvents.js`.
- **Wallet top-up** — real card tokenization via the official Square In-App Payments SDK
  (`square_in_app_payments`), using the buyer-verification flow
  (`startCardEntryFlowWithBuyerVerification`) since this account's Square integration requires
  SCA/3D-Secure (same reason the website passes `billingContact` into its own `tokenize()`
  call). Discovered and fixed a real backend gap while building this: the mobile SDK's
  verification token is separate from the card nonce, and the backend's `squareCreatePayment()`
  didn't have anywhere to put it — fixed server-side (`squareClient.js`,
  `POST /wallet/topup`'s `verificationToken` field) before this screen was wired up against it.

## What's NOT built yet (real gaps, not silently skipped)

- **A real Firebase project.** All the inbound-calling CODE is in place (see above) — what's
  missing is the actual Firebase project this repo can't create for you, plus the Twilio Push
  Credential that depends on it. See "Inbound calling setup" above for the exact steps.
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
    wallet/       — balance + transaction ledger, real Square In-App Payments top-up
    invoices/     — read-only list/detail (server-generated)
    profile/      — current user, edit profile, change password, logout
    home/         — authenticated app shell (bottom nav + Socket.IO connection lifetime)
```

State management is `provider` (ChangeNotifier) — chosen for its small footprint and directness
given how few screens this app has so far; nothing here depends on it deeply enough that
switching to Riverpod later would be painful if that ever matters.
