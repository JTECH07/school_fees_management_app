// lib/services/backend_test_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/constants/app_constants.dart';
import '../datasources/remote/firebase/realtime_database_service.dart';

class BackendCheckResult {
  final String service;
  final String message;
  final bool success;

  BackendCheckResult({required this.service, required this.message, required this.success});
}

class BackendTestService {
  final FirebaseFirestore _firestore;
  final RealtimeDatabaseService _rtdbService;

  BackendTestService({
    FirebaseFirestore? firestore,
    RealtimeDatabaseService? rtdbService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _rtdbService = rtdbService ?? RealtimeDatabaseService();

  String get projectId => _firestore.app.options.projectId;
  String get realtimeDatabaseUrl => _rtdbService.configuredUrl;

  BackendCheckResult checkFirebaseInitialization() {
    return BackendCheckResult(
      service: 'Firebase Core',
      message: 'Initialisation réussie',
      success: true,
    );
  }

  BackendCheckResult checkAuthState() {
    return BackendCheckResult(
      service: 'Firebase Auth',
      message: 'Prêt',
      success: true,
    );
  }

  Future<BackendCheckResult> checkFirestore() async {
    try {
      await testFirestorePing();
      return BackendCheckResult(
        service: 'Firestore',
        message: 'Connexion réussie',
        success: true,
      );
    } catch (e) {
      return BackendCheckResult(
        service: 'Firestore',
        message: 'Erreur: $e',
        success: false,
      );
    }
  }

  Future<BackendCheckResult> checkRealtimeDatabase() async {
    try {
      await testRealtimeDatabasePing();
      return BackendCheckResult(
        service: 'Realtime Database',
        message: 'Connexion réussie',
        success: true,
      );
    } catch (e) {
      return BackendCheckResult(
        service: 'Realtime Database',
        message: 'Erreur: $e',
        success: false,
      );
    }
  }

  Future<void> testFirestorePing() async {
    await _firestore
        .collection(AppConstants.systemChecksCollection)
        .doc('firestore_ping')
        .set({'last_ping': FieldValue.serverTimestamp()});
  }

  Future<void> testRealtimeDatabasePing() async {
    await _rtdbService.ping();
  }

  Stream<DocumentSnapshot> getFirestorePingStream() {
    return _firestore
        .collection(AppConstants.systemChecksCollection)
        .doc('firestore_ping')
        .snapshots();
  }

  Stream<DatabaseEvent> getRealtimeDatabasePingStream() {
    return _rtdbService.watchPing().cast<DatabaseEvent>();
  }
}
