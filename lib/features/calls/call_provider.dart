import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'voice_service.dart';

enum ActiveCallState { idle, connecting, ringing, connected, ended }

/// Drives the in-call UI from the REAL CallEvent stream the Twilio Voice SDK emits — never a
/// simulated/timed fake ringing state. If the SDK doesn't emit an event, this provider doesn't
/// move, on purpose.
class CallProvider extends ChangeNotifier {
  final _voice = VoiceService.instance;
  StreamSubscription<CallEvent>? _sub;

  ActiveCallState state = ActiveCallState.idle;
  String? activeNumber;
  bool isMuted = false;
  bool isOnSpeaker = false;
  String? errorMessage;

  void _listen() {
    _sub ??= _voice.events.listen((event) {
      switch (event) {
        case CallEvent.ringing:
          state = ActiveCallState.ringing;
          break;
        case CallEvent.connected:
        case CallEvent.reconnected:
        case CallEvent.answer:
          state = ActiveCallState.connected;
          break;
        case CallEvent.callEnded:
        case CallEvent.declined:
          state = ActiveCallState.ended;
          activeNumber = null;
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

  Future<void> startCall(String number) async {
    _listen();
    errorMessage = null;
    state = ActiveCallState.connecting;
    activeNumber = number;
    notifyListeners();

    try {
      final identity = await _voice.register();
      final placed = await _voice.placeCall(from: identity, to: number);
      if (!placed) {
        errorMessage = 'Could not start the call.';
        state = ActiveCallState.idle;
        activeNumber = null;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = ActiveCallState.idle;
      activeNumber = null;
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
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
