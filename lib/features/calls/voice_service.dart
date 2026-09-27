import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'call_repository.dart';

/// Wraps the twilio_voice plugin (real Twilio Programmable Voice SDK — cybex-dev/twilio_voice
/// v0.5.0). Verified against the plugin's actual source (TwilioCallPlatform / TwilioVoicePlatform
/// interfaces on GitHub) since its own README examples show `toggleMute(isMuted: true)`/
/// `toggleSpeaker(speakerIsOn: true)` as named arguments, but the real interface takes them
/// positional — `toggleMute(bool isMuted)` / `toggleSpeaker(bool speakerIsOn)`. Trust this
/// file's calls over the README if they disagree.
///
/// Handles BOTH directions. Outbound needs Android PhoneAccount registration
/// (_requestAndroidCallingPermissions, unconditional — a real device-tested bug: this used to be
/// gated behind Firebase availability on the wrong assumption that it was inbound-only, which
/// silently broke outbound calling on every device without a configured Firebase project, found
/// 2026-09-24 against a real test account). Inbound additionally needs Firebase Cloud
/// Messaging — the ONLY way twilio_voice delivers an incoming-call notification on Android —
/// which needs a real Firebase project this repo can't include (see firebase_options.dart's
/// placeholder and README.md's "Inbound calling setup"). Without a REAL Firebase project,
/// register() degrades to accessToken alone (deviceToken omitted) — but this degrading has to
/// be an explicit try/catch around the actual FCM call, not just a check of
/// Firebase.apps.isNotEmpty: a placeholder firebase_options.dart still lets
/// Firebase.initializeApp() register an app locally, so that check alone doesn't catch it —
/// the real failure only surfaces when FirebaseMessaging actually talks to Firebase's servers,
/// as a real uncaught exception ("Please set your Application ID") that used to abort outbound
/// calling too before this was caught here (found against a real device, 2026-09-27).
///
/// Every call this places goes through the SAME TwiML webhook the browser softphone and
/// GET /calls/incoming/token already use server-side (controllers/twilioWebhookController.js) —
/// the TwiML App's Voice Request URL now points at this Node API (repointed and verified
/// 2026-09-23), so this is a real, billed, recorded call exactly like any other CallDrag call.
/// Same for inbound: the number that's actually configured to ring this agent's Voice SDK
/// identity is entirely a server-side concern (includes/twilio_jwt.php's identity scheme),
/// unchanged here.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final _callRepository = CallRepository();
  bool _registered = false;
  bool _androidCallingAccountRequested = false;

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  /// Registers this device with a fresh Voice Access Token, and — if Firebase is configured —
  /// an FCM device token so incoming calls can reach this device too. Access tokens are
  /// short-lived (see services/twilioTokenService.js on the backend) — call this again before
  /// placing a call if it's been a while since the last registration, rather than assuming it's
  /// still valid.
  Future<String> register() async {
    final result = await _callRepository.getVoiceToken();

    // PhoneAccount registration (Android's ConnectionService) is needed for OUTBOUND calls
    // too, not just inbound — this was previously gated behind Firebase availability on the
    // wrong assumption that it was inbound-only, which silently broke outbound calling on any
    // device without a configured Firebase project. Unconditional now; only the FCM device
    // token (genuinely inbound-only) stays gated behind Firebase.
    await _requestAndroidCallingPermissions();

    // _firebaseAvailable alone isn't enough to know FCM will actually work — a placeholder
    // firebase_options.dart (no real Firebase project yet) still lets Firebase.initializeApp()
    // register an app locally (Firebase.apps.isNotEmpty becomes true), so this branch runs, but
    // the ACTUAL FirebaseMessaging network call against that fake project then throws a real,
    // uncaught exception ("Please set your Application ID") — confirmed against a real device
    // 2026-09-27. That exception has to be caught HERE, not just gated on _firebaseAvailable,
    // or it aborts the whole register()/placeCall() chain and breaks outbound calling too, even
    // though this whole block is only ever meant to affect inbound.
    String? deviceToken;
    if (_firebaseAvailable) {
      try {
        deviceToken = await _ensureFcmToken();
      } catch (e) {
        deviceToken = null;
      }
    }

    await TwilioVoicePlatform.instance.setTokens(accessToken: result.token, deviceToken: deviceToken);
    _registered = true;
    return result.identity;
  }

  /// Real permission requests, Android only — registers this app's PhoneAccount with Android's
  /// ConnectionService, required for BOTH outbound and inbound calling on this plugin (twilio_voice's
  /// README: "Android Setup" / "Phone Account" — not inbound-only, despite how that section reads).
  /// A no-op, not a mock, on iOS: these calls are genuinely unnecessary there. Runs regardless of
  /// whether Firebase is configured — Firebase only gates the FCM device token, which really is
  /// inbound-only.
  Future<void> _requestAndroidCallingPermissions() async {
    if (kIsWeb || !Platform.isAndroid || _androidCallingAccountRequested) return;
    _androidCallingAccountRequested = true;
    final platform = TwilioVoicePlatform.instance;
    await platform.requestReadPhoneNumbersPermission();
    await platform.registerPhoneAccount();
    await platform.requestCallPhonePermission();
    await platform.requestReadPhoneStatePermission();
  }

  /// Requests notification permission (iOS/Android 13+) and returns the current FCM token,
  /// also wiring up onTokenRefresh so a rotated token re-registers with Twilio automatically —
  /// without this, Twilio keeps the stale binding and incoming calls silently stop reaching
  /// this device (see twilio_voice's own README warning on this exact failure mode).
  Future<String?> _ensureFcmToken() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    messaging.onTokenRefresh.listen((newToken) async {
      // Needs a currently-valid access token to re-bind against — if this fires while the
      // agent isn't actively registered (e.g. logged out), there's nothing to refresh yet;
      // the next real register() call will pick up the new token anyway via getToken() below.
      if (!_registered) return;
      final result = await _callRepository.getVoiceToken();
      await TwilioVoicePlatform.instance.setTokens(accessToken: result.token, deviceToken: newToken);
    });

    return messaging.getToken();
  }

  bool get isRegistered => _registered;

  Stream<CallEvent> get events => TwilioVoicePlatform.instance.callEventsListener;

  /// The caller/callee number and direction for whatever call is currently active — only
  /// meaningful after a `ringing` or later event (see the plugin's own ActiveCall doc comment).
  /// Used to tell an inbound call (answered via Android's native ConnectionService UI, which
  /// this app never draws itself) apart from an outbound one placed through placeCall(), so
  /// call_provider.dart knows when to navigate INTO the in-call screen reactively instead of
  /// the dialer having pushed it proactively.
  ActiveCall? get activeCall => TwilioVoicePlatform.instance.call.activeCall;

  /// Places a real outbound call. `to` is the raw phone number the customer will be dialed at
  /// (webhooks/twiml_voice.php / twilioWebhookController.js resolves the actual caller-ID
  /// number and runs the real DNC check server-side — this app never needs to duplicate that).
  /// `from` is this agent's own Voice SDK identity (whatever register() returned).
  ///
  /// extraOptions carries `Platform: 'mobile'` — the one custom param the backend's outbound
  /// webhook reads to log this call with channel='mobile' instead of 'browser'
  /// (models/callRepository.js's create()).
  Future<bool> placeCall({required String from, required String to}) async {
    final result = await TwilioVoicePlatform.instance.call.place(
      from: from,
      to: to,
      extraOptions: const {'Platform': 'mobile'},
    );
    return result ?? false;
  }

  Future<void> hangUp() => TwilioVoicePlatform.instance.call.hangUp();
  Future<void> answer() => TwilioVoicePlatform.instance.call.answer();
  Future<void> toggleMute(bool isMuted) => TwilioVoicePlatform.instance.call.toggleMute(isMuted);
  Future<void> toggleSpeaker(bool speakerIsOn) => TwilioVoicePlatform.instance.call.toggleSpeaker(speakerIsOn);
  Future<void> sendDigits(String digits) => TwilioVoicePlatform.instance.call.sendDigits(digits);
  Future<String?> getCurrentCallSid() => TwilioVoicePlatform.instance.call.getSid();
}
