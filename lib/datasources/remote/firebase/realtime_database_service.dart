import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_constants.dart';

class RealtimeDatabaseService {
  FirebaseDatabase get database {
    final app = Firebase.app();
    final configuredUrl = AppConstants.firebaseRealtimeDatabaseUrl.trim();
    final appUrl = app.options.databaseURL?.trim() ?? '';
    final databaseUrl = configuredUrl.isNotEmpty ? configuredUrl : appUrl;

    if (databaseUrl.isNotEmpty) {
      return FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
    }

    return FirebaseDatabase.instanceFor(app: app);
  }

  String get configuredUrl {
    final appUrl = Firebase.app().options.databaseURL?.trim() ?? '';
    return AppConstants.firebaseRealtimeDatabaseUrl.trim().isNotEmpty
        ? AppConstants.firebaseRealtimeDatabaseUrl.trim()
        : appUrl;
  }

  bool get hasUsableDatabaseUrl => configuredUrl.isNotEmpty;

  DatabaseReference get systemChecksRef =>
      database.ref(AppConstants.systemChecksCollection);

  Future<void> ping() async {
    final now = DateTime.now().toIso8601String();
    await systemChecksRef.child('rtdb_ping').set(<String, dynamic>{
      'source': 'flutter_app',
      'timestamp': now,
      'status': 'ok',
    });
  }

  Stream<Map<String, dynamic>?> watchPing() {
    return systemChecksRef.child('rtdb_ping').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map<Object?, Object?>) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }

      return null;
    });
  }
}
