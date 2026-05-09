class AppConstants {
  static const String usersCollection = 'users';
  static const String etudiantsCollection = 'etudiants';
  static const String secretairesCollection = 'secretaires';
  static const String administrateursCollection = 'administrateurs';
  static const String inscriptionsCollection = 'inscriptions';
  static const String paiementsCollection = 'paiements';
  static const String echeancesCollection = 'echeances';
  static const String recusCollection = 'recus';
  static const String filieresCollection = 'filieres';
  static const String niveauxCollection = 'niveaux';
  static const String anneesAcademiquesCollection = 'anneesAcademiques';
  static const String fraisScolariteCollection =
      'fraisScolarite'; // Pour l'admin pour définir les frais
  static const String systemChecksCollection = 'system_checks';
  static const String firebaseRealtimeDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
  );

  static const List<String> niveaux = ['L1', 'L2', 'L3', 'M1', 'M2'];

  static String get appName => 'UATM Paiements';
}
