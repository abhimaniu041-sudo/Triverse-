// Placeholder file. This will be AUTO-GENERATED when you run:
//   flutterfire configure
//
// Steps (one-time):
//   1. npm install -g firebase-tools
//   2. dart pub global activate flutterfire_cli
//   3. firebase login
//   4. cd into the project root and run: flutterfire configure
//      - Select your Firebase project (or create one)
//      - Choose Android (and optionally iOS) platforms
//
// After that command completes, this file will be replaced with real config
// values (apiKey, appId, projectId, etc.) for every platform you selected.
//
// Until you run the command, the app will fail at Firebase.initializeApp().
// So: DO NOT skip this step.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Run "flutterfire configure" to set them up.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured yet. '
          'Run "flutterfire configure" from the project root to generate this file.',
        );
    }
  }
}
