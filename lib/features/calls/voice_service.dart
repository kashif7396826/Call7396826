import 'package:twilio_voice/twilio_voice.dart';
import 'call_repository.dart';

/// Wraps the twilio_voice plugin (real Twilio Programmable Voice SDK — cybex-dev/twilio_voice
/// v0.5.0) for OUTBOUND calling only. Verified against the plugin's actual source
/// (TwilioCallPlatform / TwilioVoicePlatform interfaces on GitHub) since its own README
/// examples show `toggleMute(isMuted: true)`/`toggleSpeaker(speakerIsOn: true)` as named
/// arguments, but the real interface takes them positional — `toggleMute(bool isMuted)` /
/// `toggleSpeaker(bool speakerIsOn)`. Trust this file's calls over the README if they disagree.
///
/// INBOUND calls are NOT wired up here — receiving a call requires Firebase Cloud Messaging
/// (a `VoiceFirebaseMessagingService` registered in AndroidManifest.xml, a Firebase project,
/// `google-services.json`) which this project has no real Firebase project/credentials for yet.
/// That's a genuine, separate setup step for whoever deploys this app for real — not something
/// to fake with a placeholder config. See README.md's "What's NOT built yet" section.
///
/// Every call this places goes through the SAME TwiML webhook the browser softphone and
/// GET /calls/incoming/token already use server-side (controllers/twilioWebhookController.js) —
/// once the pending TwiML App repoint (test11.dataposting.online's CLAUDE.md) happens, this
/// becomes a real, billed, recorded call exactly like any other CallDrag call.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final _callRepository = CallRepository();
  bool _registered = false;

  /// Registers this device with a fresh Voice Access Token. Access tokens are short-lived
  /// (see services/twilioTokenService.js on the backend) — call this again before placing a
  /// call if it's been a while since the last registration, rather than assuming it's still
  /// valid.
  Future<String> register() async {
    final result = await _callRepository.getVoiceToken();
    await TwilioVoicePlatform.instance.setTokens(accessToken: result.token);
    _registered = true;
    return result.identity;
  }

  bool get isRegistered => _registered;

  Stream<CallEvent> get events => TwilioVoicePlatform.instance.callEventsListener;

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
  Future<void> toggleMute(bool isMuted) => TwilioVoicePlatform.instance.call.toggleMute(isMuted);
  Future<void> toggleSpeaker(bool speakerIsOn) => TwilioVoicePlatform.instance.call.toggleSpeaker(speakerIsOn);
  Future<void> sendDigits(String digits) => TwilioVoicePlatform.instance.call.sendDigits(digits);
  Future<String?> getCurrentCallSid() => TwilioVoicePlatform.instance.call.getSid();
}
