import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'voice_service.dart';

enum ActiveCallState { idle, connecting, ringing, connected, ended }

/// Drives the in-call UI from the REAL CallEvent stream the Twilio Voice SDK emits — never a
/// simulated/timed fake ringing state. If the SDK doesn't emit an event, this provider doesn't
/// move, on purpose.
///
/// Handles both directions. An outbound call is proactively started via startCall() — the
/// caller (DialerScreen, ContactDetailScreen) pushes InCallScreen itself before awaiting it.
/// An inbound call answered through Android's native ConnectionService UI (this app never draws
/// its own ringing screen — twilio_voice's README covers why) arrives here as a `ringing` event
/// this provider did NOT cause via startCall(); [onIncomingCallActive] fires once it's
/// answered so the app shell (home_shell.dart) can push InCallScreen reactively instead.
class CallProvider extends ChangeNotifier {
  final _voice = VoiceService.instance;
  StreamSubscription<CallEvent>? _sub;
  bool _startedByUs = false;

  ActiveCallState state = ActiveCallState.idle;
  String? activeNumber;
  bool isIncoming = false;
  bool isMuted = false;
  bool isOnSpeaker = false;
  String? errorMessage;

  /// Set by home_shell.dart. Fires once, the moment an inbound call this provider did NOT
  /// initiate becomes connected, so the shell can navigate to InCallScreen reactively.
  void Function()? onIncomingCallActive;

  void _listen() {
    _sub ??= _voice.events.listen((event) {
      switch (event) {
        case CallEvent.ringing:
          _adoptInboundCallIfNeeded();
          state = ActiveCallState.ringing;
          break;
        case CallEvent.connected:
        case CallEvent.reconnected:
        case CallEvent.answer:
          final wasAlreadyActive = state == ActiveCallState.connected;
          _adoptInboundCallIfNeeded();
          state = ActiveCallState.connected;
          if (isIncoming && !wasAlreadyActive) onIncomingCallActive?.call();
          break;
        case CallEvent.callEnded:
        case CallEvent.declined:
          state = ActiveCallState.ended;
          activeNumber = null;
          isIncoming = false;
          _startedByUs = false;
          isMuted = false;
          isOnSpeaker = false;
          break;
        case CallEvent.mute:
          isMuted = true;
          break;
        case CallEvent.unmute:
          isMuted = false;
          break;
        case CallEvent.speakerOn:
          isOnSpeaker = true;
          break;
        case CallEvent.speakerOff:
          isOnSpeaker = false;
          break;
        default:
          break;
      }
      notifyListeners();
    });
  }

  /// If this event wasn't caused by our own startCall(), it must be an inbound call reaching
  /// this device — pull its number/direction from the plugin's own activeCall so the UI has
  /// something real to show, instead of the blank activeNumber startCall() would have set.
  void _adoptInboundCallIfNeeded() {
    if (_startedByUs || activeNumber != null) return;
    final active = _voice.activeCall;
    if (active == null) return;
    isIncoming = active.callDirection == CallDirection.incoming;
    activeNumber = isIncoming ? active.fromFormatted : active.toFormatted;
  }

  /// Call once, early (e.g. app startup while authenticated) so an inbound call reaches this
  /// device even before the agent has placed one themselves — mirrors what register() already
  /// does for outbound, just not deferred until the first dial.
  void listenForIncomingCalls() => _listen();

  Future<void> startCall(String number) async {
    _listen();
    errorMessage = null;
    state = ActiveCallState.connecting;
    activeNumber = number;
    isIncoming = false;
    _startedByUs = true;
    notifyListeners();

    try {
      final identity = await _voice.register();
      final placed = await _voice.placeCall(from: identity, to: number);
      if (!placed) {
        errorMessage = 'Could not start the call.';
        state = ActiveCallState.idle;
        activeNumber = null;
        _startedByUs = false;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = ActiveCallState.idle;
      activeNumber = null;
      _startedByUs = false;
    }
    notifyListeners();
  }

  Future<void> hangUp() async {
    await _voice.hangUp();
    state = ActiveCallState.ended;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    await _voice.toggleMute(!isMuted);
  }

  Future<void> toggleSpeaker() async {
    await _voice.toggleSpeaker(!isOnSpeaker);
  }

  Future<void> sendDigit(String digit) => _voice.sendDigits(digit);

  void reset() {
    state = ActiveCallState.idle;
    activeNumber = null;
    isIncoming = false;
    _startedByUs = false;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
