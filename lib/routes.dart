import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uatm_paiements/screens/secretaire/validation_paiement_screen.dart';
import 'package:uatm_paiements/screens/secretaire/historique_secretaire_screen.dart';

import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/gestion_annees_screen.dart';
import 'screens/admin/gestion_filieres_screen.dart';
import 'screens/admin/gestion_inscriptions_screen.dart';
import 'screens/admin/gestion_utilisateurs_screen.dart';
import 'screens/admin/consultations_rapports_screen.dart';
import 'screens/admin/validation_inscriptions_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/etudiant/etudiant_dashboard.dart';
import 'screens/etudiant/paiements_screen.dart';
import 'screens/etudiant/recus_screen.dart';
import 'screens/secretaire/secretaire_dashboard.dart';
import 'screens/secretaire/echeances_retard_screen.dart';
import 'screens/secretaire/rapports_screen.dart';
import 'screens/shared/backend_test_screen.dart';
import 'screens/shared/setup_demo_screen.dart';
import 'screens/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/backend-test',
        name: 'backend-test',
        builder: (context, state) => const BackendTestScreen(),
      ),
      GoRoute(
        path: '/setup-demo',
        name: 'setup-demo',
        builder: (context, state) => const SetupDemoScreen(),
      ),
      GoRoute(
        path: '/etudiant',
        name: 'etudiant',
        builder: (context, state) => const EtudiantDashboard(),
        routes: [
          GoRoute(
            path: 'paiements',
            name: 'etudiant-paiements',
            builder: (context, state) => const PaiementsScreen(),
          ),
          GoRoute(
            path: 'recus',
            name: 'etudiant-recus',
            builder: (context, state) => const RecusScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/secretaire',
        name: 'secretaire',
        builder: (context, state) => const SecretaireDashboard(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'validation-inscriptions',
            name: 'admin-validation-inscriptions',
            builder: (context, state) => const ValidationInscriptionsScreen(),
          ),
          GoRoute(
            path: 'filieres',
            name: 'admin-filieres',
            builder: (context, state) => const GestionFilieresScreen(),
          ),
          GoRoute(
            path: 'annees',
            name: 'admin-annees',
            builder: (context, state) => const GestionAnneesScreen(),
          ),
          GoRoute(
            path: 'inscriptions',
            name: 'admin-inscriptions',
            builder: (context, state) => const GestionInscriptionsScreen(),
          ),
          GoRoute(
            path: 'utilisateurs',
            name: 'admin-utilisateurs',
            builder: (context, state) => const GestionUtilisateursScreen(),
          ),
          GoRoute(
            path: 'rapports',
            name: 'admin-rapports',
            builder: (context, state) => const ConsultationsRapportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/secretaire/retards',
        name: 'secretaire-retards',
        builder: (context, state) => const EcheancesRetardScreen(),
      ),
      GoRoute(
        path: '/secretaire/rapports',
        name: 'secretaire-rapports',
        builder: (context, state) => const RapportsScreen(),
      ),
      GoRoute(
        path: '/secretaire/validations',
        name: 'secretaire-validations',
        builder: (context, state) => const ValidationPaiementScreen(),
      ),
      GoRoute(
        path: '/secretaire/historique',
        name: 'secretaire-historique',
        builder: (context, state) => const HistoriqueSecretaireScreen(),
      ),
    ],
  );
});
