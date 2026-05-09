import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();

  runApp(const ProviderScope(child: UatmPaiementsApp()));
}

Future<void> _initializeFirebase() async {
  try {
    if (kIsWeb ||
        {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
          TargetPlatform.windows,
        }.contains(defaultTargetPlatform)) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on UnsupportedError catch (error) {
    debugPrint('Firebase non initialisé sur cette plateforme: $error');
  } catch (error) {
    debugPrint('Erreur lors de l\'initialisation Firebase: $error');
  }
}
