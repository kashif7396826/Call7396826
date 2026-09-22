// PLACEHOLDER — this file has no real project behind it and will be COMPLETELY OVERWRITTEN
// the moment you run `flutterfire configure` against a real Firebase project. Its shape (a
// DefaultFirebaseOptions class with a currentPlatform getter) matches exactly what that CLI
// tool generates, on purpose — that's not a coincidence, it's so `flutterfire configure`
// recognizes and replaces this file in place rather than needing you to delete it first.
//
// Until you run that command, every value below is fake. main.dart wraps Firebase
// initialization in a try/catch specifically so a fake/placeholder config here doesn't crash
// the rest of the app — auth, calls, contacts, wallet, everything else keeps working; only
// inbound calling (which needs a real Firebase project for FCM push, see README.md's "Inbound
// calling setup") stays unavailable until you configure this for real.
//
// See README.md for the exact steps: create a Firebase project, add an Android app with this
// project's applicationId, run `flutterfire configure`, then re-run the app.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — run `flutterfire configure`. '
        'This app targets Android/iOS calling; web was never a real target here.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ${defaultTargetPlatform.name} — '
          'run `flutterfire configure`.',
        );
    }
  }

  // Every value below is a placeholder — `flutterfire configure` overwrites this entire file
  // with your real project's values. Left in this obviously-fake shape (not null, not empty
  // strings) so a forgotten configuration step fails loudly with a real Firebase "invalid API
  // key" style error instead of a confusing null-check crash somewhere else.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    projectId: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    projectId: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    iosBundleId: 'com.calldrag.calldragMobile',
  );
}
