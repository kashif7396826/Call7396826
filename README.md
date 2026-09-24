# CallDrag Mobile (Flutter)

Real mobile client for the CallDrag call-tracking CRM, talking to the live Node.js API at
**api.calldrag.com** (`/home/zsziykvi/api.calldrag.com` on the host, a separate project from
this one) — which itself reads/writes the same production MySQL database as the PHP web app at
**calldrag.com** (physically hosted at `/home/zsziykvi/test11.dataposting.online` — `calldrag.com`
is a domain alias into that same docroot). No mock data, no fake screens, no simulated calling
anywhere in this codebase, per this project's explicit no-mock policy.

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

# 4. Generate the real launcher icon (navy/cyan, matching the brand — see assets/icon/) into
#    the android/ scaffold step 2 just created. Safe to re-run any time the source SVGs change.
flutter pub run flutter_launcher_icons

# 5. Apply the manifest/permission additions below, then run
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

### Photo/gallery access (publisher logo upload)

`image_picker` (used only by the publisher self-service profile screen's company-logo picker)
declares its own required permissions via its plugin manifest — no manual
`AndroidManifest.xml` edit needed. On Android 13+ it uses the system Photo Picker (no runtime
permission prompt at all); on older versions it requests storage/media read access at the point
the user taps "Add Company Logo," not at app launch.

### Android minSdkVersion

`square_in_app_payments` (the official Square SDK, used for wallet top-up) requires
**`minSdkVersion 28`** (Android 9) — higher than Flutter's own template default. After running
`flutter create` (step 2 above), open `android/app/build.gradle` (or `build.gradle.kts`) and
raise `minSdkVersion`/`minSdk` to `28` if it isn't already. `twilio_voice` doesn't impose a
higher floor than this.

### Android targetSdkVersion (check this before every Play Store submission, not just once)

Google Play enforces a minimum `targetSdkVersion` for all new app submissions and updates, and
**that minimum changes roughly once a year** — this README can't hardcode a number that stays
correct. Before your first submission (and before every update after that), check Play
Console's own current requirement at
[Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
and set `targetSdkVersion`/`targetSdk` in `android/app/build.gradle` explicitly to match —
don't rely on whatever Flutter's template defaults to for the SDK version you happen to have
installed. Play Console will reject an upload that doesn't meet the current minimum, so this is
self-verifying at submission time even if you skip the manual check.

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
production API. **As of 2026-09-23, this is fully live**: a real Let's Encrypt certificate for
`api.calldrag.com` was issued via `acme.sh` (this account's AutoSSL feature is disabled, so the
host's own cPanel SSL UI wasn't an option — `acme.sh`'s `cpanel_uapi` deploy hook installed it,
working around a CageFS `uapi` proxy quirk that mangled raw multi-line PEM content passed as
inline shell arguments) and verified end-to-end (`openssl s_client` shows the correct CN, real
issuer, real expiry; `GET /health` returns 200 over it). The live Twilio TwiML App's Voice
Request URL has also been repointed from the old PHP webhook
(`webhooks/twiml_voice.php`) to this API's own
(`https://api.calldrag.com/api/v1/webhooks/twilio/voice`) and confirmed via an independent
re-fetch of the TwiML App's config — outbound calls placed from this app now get their TwiML
from the Node path it was actually built to share with the browser softphone.

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
- **Live call control** — `POST /calls/:id/end`, `/transfer`, `/hold`, `/resume`, and
  `/recording/pause`/`/resume`/`/stop`, all wired up from the call detail screen.
- **Contacts** — full real CRUD against `/contacts` (list with search, create, edit, delete),
  including a "Call" button that starts a real outbound call to that contact.
- **Invoices** — real, read-only data from `/invoices` (server-generated, Super Admin only via
  the website — this app just lists/views them), linked from the Wallet screen.
- **Edit Profile / Change Password** — real `PATCH /users/me` and `POST /users/me/password`
  (already verified server-side against a real account before this UI existed — see the
  Node API's own commit history). Not shown for publisher accounts, matching the backend's own
  `requireNonPublisher()` gate on these endpoints.
- **Publisher role** — a completely separate app shell (`features/publisher/`), routed to
  automatically at login for a publisher account. Dashboard, assigned numbers with per-number
  stats, call history (all-numbers or filtered to one), and recording playback — all real data
  from `/publisher/*`, scoped entirely server-side through `tracking_numbers.publisher_user_id`
  (never client-level scoping, which would leak the rest of the client's numbers). No live
  calling, contacts, or wallet — a publisher is blocked from those server-side too. Publisher
  self-service profile editing is now ported too: `publisher/settings.php`'s richer field set
  (company name/logo, phone, timezone, notify-on-new-call) via the new `GET/PATCH /publisher/me`
  and `POST /publisher/me/password` endpoints, including a real company-logo upload
  (`image_picker` + multipart) — the uploaded file is written straight into the PHP app's own
  `assets/uploads/publishers/` directory (both apps share the same host/account) so it's served
  from the exact same public URL the web app already uses. Live-tested end-to-end 2026-09-23
  against real publisher user id 10: real file written to disk, real DB row updated, full logo
  URL round-tripped through `authService.js`'s `sanitizeUser()`, then reverted back to that
  user's original values in cleanup.
- **SMS** — a genuinely new capability, ahead of the web app (explicit sign-off — see the
  backend's own commit history): real send/receive via `/sms/threads`, a conversation view per
  contact, and live push for a real inbound message (`sms:event` over the same Socket.IO
  connection call events use). Send goes through the same DNC/client-suspension checks as
  outbound calling before a real send call. Reachable from the Messages tab or a contact's own
  "Message" button. Supports both providers — sending picks whichever provider has a default
  outbound number configured for the client (Twilio first, Telnyx as fallback). The Telnyx send
  path was live-tested against the real Telnyx API on 2026-09-23, found a real account-config
  gap (no Telnyx number was attached to a Messaging Profile — `TELNYX_MESSAGING_PROFILE_ID` had
  never been set), and that gap is now fixed for real: a Messaging Profile already existed on
  the account, just unused, so its id was saved to `app_settings`, its inbound webhook URL was
  set (was `null`), and both of the account's live Telnyx numbers were attached to it via a
  real `PATCH /phone_numbers/{id}/messaging` call. Re-verified after: the same fictional-number
  smoke test now fails only on the (intentionally invalid) destination, not the `from` number —
  Telnyx SMS sending is genuinely live for both providers now.
- **Outbound and inbound calling** — real Twilio Voice SDK integration (`twilio_voice`
  plugin). Outbound: `GET /calls/incoming/token` for the access token, the real outbound TwiML
  webhook server-side. Inbound: FCM device-token registration with token-refresh handling,
  Android calling-account/permission setup, and `activeCall`-based direction detection so
  `home_shell.dart` navigates into the in-call screen reactively when a call answered via the
  native ConnectionService/CallKit UI becomes active — this app never draws its own
  incoming-call screen. Both need a real Firebase project to actually test inbound (see
  "Inbound calling setup" above) — the code doesn't fake that in the meantime, it degrades to
  outbound-only. Outbound is otherwise fully live: the TwiML App now points at this API's own
  webhook (see the SSL/repoint note above) — its real-call happy path (as opposed to the
  webhook wiring, which is verified) still hasn't been exercised end-to-end, since this session
  has consistently declined to place an actual live phone call unprompted.
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
- **Hold's real-conference happy path.** `POST /calls/:id/hold`/`/resume` are wired up in the
  call detail screen and real on the backend (a genuine Conference-based call topology, Twilio
  Conference Participant hold) — but hasn't been exercised against an actual live call
  (deliberately: this session won't place a real phone call to test it). Also needs
  `schema_phase26_conference_calling.sql` run before it does anything but 501 — see the Node
  API's own commit history.

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
    home/         — staff authenticated app shell (bottom nav + Socket.IO connection lifetime)
    publisher/    — separate, narrower shell + screens for the Publisher role
    sms/          — conversation list + thread view, real send/receive
```

State management is `provider` (ChangeNotifier) — chosen for its small footprint and directness
given how few screens this app has so far; nothing here depends on it deeply enough that
switching to Riverpod later would be painful if that ever matters.
