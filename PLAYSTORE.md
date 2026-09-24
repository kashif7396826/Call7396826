# Play Store submission prep

Content to paste into Google Play Console. Nothing here can be submitted by an AI agent —
Play Console requires your own Google account, the one-time $25 registration fee, and a real
signed build. This file exists so that work is copy-paste-ready when you get there.

**Before any of this matters:** this app has never been built (see the README's own warning
at the top). Get a real `flutter build appbundle` succeeding first — the exact permission set
below can only be confirmed once the native Android manifest actually exists and the plugins'
own manifests have merged into it.

## App identity

- **App name:** CallDrag
- **Package name / applicationId:** `com.calldrag.calldrag_mobile` — **confirmed and locked in 2026-09-23**, do not change. Use exactly `flutter create --org com.calldrag --project-name calldrag_mobile .` (as in the README's Setup section) so the generated `applicationId` matches this value exactly. This cannot be changed after the first Play Store upload, ever — if a future rebuild ever generates something different, that's a bug, not an update.
- **Category:** Business (primary). Play may also prompt for a Communication-adjacent declaration because of the VoIP calling feature — see "Permissions declaration" below.
- **Privacy Policy URL:** `https://calldrag.com/privacy.php` — real, live, verified `200` this session. Required in Play Console → App content → Privacy Policy; publishing is blocked without it, and it's a UI field, not something this repo can set for you — don't forget it at submission time.

## Store listing copy

**Short description** (80 characters max):
```
Real-time call tracking CRM — make calls, track leads, manage your wallet.
```
(79 chars)

**Full description** (4000 characters max):
```
CallDrag is the mobile companion to the CallDrag call-tracking CRM — place and receive real
calls, manage your leads, and keep an eye on your account, all from your phone.

WHAT YOU CAN DO
• Place and receive calls through your CallDrag numbers, right from the app
• View your full call history with recordings, duration, and outcome
• Manage contacts and leads as they come in from real inbound calls
• Send and receive SMS conversations tied to your contacts
• Track your wallet balance and top up with a card
• Publisher accounts: see performance on your assigned numbers only

BUILT FOR TEAMS THAT TRACK EVERY CALL
CallDrag exists to give sales and marketing teams accurate attribution and a real record of
every call and text — this app extends that same real-time system to your phone, not a
separate, disconnected mobile experience.

An active CallDrag account is required. Visit calldrag.com to learn more or get started.
```

## Permissions declaration

Google Play requires an explanation for any "restricted" permission (phone-related, in
particular) before it'll allow the app to request it. Draft justifications below, grounded in
what this app's real calling feature (`twilio_voice` / Telnyx WebRTC SDKs — see README's
Architecture section) actually needs. **Confirm the exact final list against the real merged
`AndroidManifest.xml` after your first build** — plugin manifests can add permissions beyond
what's listed here.

| Permission | Why the app needs it |
|---|---|
| `RECORD_AUDIO` | Core calling feature — carries your side of the audio on a real VoIP call placed or received through the app. Never accessed outside an active call. |
| `POST_NOTIFICATIONS` | Shows the incoming-call notification (via Firebase Cloud Messaging) and in-call/ongoing-call status notification required by Android for foreground calling services. |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_PHONE_CALL` | Keeps an active VoIP call alive and visible to the user while the app is backgrounded, matching standard Android calling-app behavior. |
| `READ_PHONE_STATE` (if present after build) | Used by the calling SDK to detect a real incoming cellular call so it can correctly pause/yield the VoIP call, avoiding two calls colliding. Not used to read the phone number, call log, or any other device identifier. |
| `INTERNET` / `ACCESS_NETWORK_STATE` | Every feature in this app is live data from the CallDrag API — there is no offline/local-only mode. |
| `READ_MEDIA_IMAGES` (Android 13+) / legacy `READ_EXTERNAL_STORAGE` (older Android) — via `image_picker` | **Corrected 2026-09-23**: `image_picker`'s own Android manifest declares this even though Android 13+'s system Photo Picker means the user is never shown a runtime permission prompt for it — Play's declaration form cares about what's declared, not just what's prompted. Only used if a Publisher account chooses to upload a company logo from their device's photo library; not requested for any other account type or feature. |

**Not requested, and why it matters for the declaration form:** no `CALL_PHONE` (the app never
places a native carrier call on your behalf), no `READ_CONTACTS` / `WRITE_CONTACTS` (CRM
contacts are server-side records, never synced from the device's address book), no
`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (no location feature exists).

## Data Safety form

Mirrors `privacy.php`'s "Mobile Application" and "Third-Party Sub-Processors" sections
(updated 2026-09-23) — keep both in sync if either changes.

| Data type | Collected? | Shared? | Purpose | Notes |
|---|---|---|---|---|
| Name, email | Yes | No | Account management | Your CallDrag login |
| Phone numbers (yours, contacts', call parties') | Yes | Yes — Twilio/Telnyx/RingCentral | App functionality | Core to call routing |
| Call/SMS audio & content | Yes (recordings, where enabled) | Yes — telephony provider | App functionality | Proxied playback only, never a raw provider URL |
| Precise/approximate location | No | — | — | Not collected |
| Photos | Only if a Publisher uploads a logo | No | App functionality | Not collected from any other account type |
| Device/push token | Yes | Yes — Firebase Cloud Messaging | App functionality (incoming-call alerts) | Not used for ads/analytics |
| Payment info | Handled by Square directly | Yes — Square | Wallet top-up | Card data never touches CallDrag's own servers |

All data is transmitted over HTTPS/TLS (the API enforces this) and users can request deletion
via the contact method in the privacy policy.

**Re-verification required before submission — this table was built from plugin documentation,
not a real build.** `square_in_app_payments` and `firebase_messaging` each bundle their own
Android manifests and could declare a permission or data flow this table doesn't account for.
After the first real `flutter build appbundle`, dump the actual merged permission list
(`aapt dump permissions <path-to-build>`) and diff it against this table's rows before filling
in Play Console's Data Safety form. If anything's missing here, add it to this table first, then
to the Play Console form — don't let the two drift apart.

## Payments Policy — wallet top-up justification

Real risk, not a settled fact — audited 2026-09-23. The wallet top-up uses Square directly,
not Google Play's Billing System. Google Play's Payments Policy generally requires digital
content/features to route through Play Billing, with a recognized exemption for apps selling
**real-world goods or services consumed outside the app** (the same category ride-hailing and
delivery apps rely on). This paragraph is the justification to paste into Play Console's app
content declarations if asked, or proactively under "Payments" in App content — it is not a
guarantee Google will accept it; read the live [Payments Policy](https://support.google.com/googleplay/android-developer/answer/9858738)
yourself before relying on it:

> CallDrag's wallet balance is not a digital in-app feature or virtual good. It is a prepaid
> balance drawn down exclusively against real-world telecommunications usage consumed outside
> the app: telephone calls placed and received over the public telephone network, SMS messages
> carried by a third-party telephony provider (Twilio/Telnyx/RingCentral), and the purchase of
> physical/carrier-assigned phone numbers. No wallet funds unlock any digital app feature,
> content, or functionality — the app's screens, contact management, and dashboards are all
> free to use regardless of wallet balance; only real telecom usage (calls, texts, number
> purchases) debits it. This mirrors terms.php's own billing description: "Usage (calls,
> minutes, recording storage, number purchases) is billed against a prepaid wallet balance."

Expect a "Communication" content rating questionnaire trigger because of the VoIP calling
feature. This app has no user-generated public content and no ads. When the content rating or
payments questionnaire asks about real-money purchases, disclose the wallet top-up honestly and
reference the justification above rather than saying "no in-app purchases."

## Submission checklist (from the 2026-09-23 compliance audit)

Do these in order — later steps depend on earlier ones landing first.

1. [ ] Real Firebase project created and `lib/firebase_options.dart` replaced with real values (`flutterfire configure`) — see README's "Inbound calling setup."
2. [ ] `flutter create --org com.calldrag --project-name calldrag_mobile .` run — confirm the generated `applicationId` is exactly `com.calldrag.calldrag_mobile`.
3. [ ] `minSdkVersion` raised to `28` in `android/app/build.gradle` (README's "Android minSdkVersion" section).
4. [ ] `targetSdkVersion` checked against Play's *current* live requirement and set explicitly (README's "Android targetSdkVersion" section) — don't skip this even though it feels redundant with step 5.
5. [ ] `flutter pub run flutter_launcher_icons` run — confirm the adaptive icon preview (Android Studio's Image Asset tool) looks right across all three real mask shapes.
6. [ ] First real `flutter build appbundle` succeeds.
7. [ ] `aapt dump permissions` run against that build — diff the real permission list against the "Permissions declaration" and "Data Safety form" tables above; update both tables if anything's missing.
8. [ ] Play Console account created, $25 fee paid (you only — not something I can do).
9. [ ] Play Console → App content → Privacy Policy set to `https://calldrag.com/privacy.php`.
10. [ ] Play Console → App content → Permissions declaration completed using the table above (post step-7 correction).
11. [ ] Play Console → App content → Data Safety form completed using the table above (post step-7 correction).
12. [ ] Payments/content-rating questionnaire answered honestly re: the wallet top-up, referencing the justification above.
13. [ ] Upload, submit for review.
