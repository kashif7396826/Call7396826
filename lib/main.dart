import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wrapped in try/catch on purpose: firebase_options.dart ships as an obvious placeholder
  // until `flutterfire configure` is run against a real project (see that file's own doc
  // comment and README.md's "Inbound calling setup"). A failure here must never take down the
  // rest of the app — auth, calls, contacts, wallet, everything else works without Firebase;
  // only inbound-call push notifications need it.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase not configured — inbound call push notifications will not work: $e');
  }

  runApp(const CallDragApp());
}
