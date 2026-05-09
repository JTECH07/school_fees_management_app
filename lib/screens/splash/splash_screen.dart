import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/roles.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          _goTo(context, '/login');
          return const _SplashBody(message: 'Redirection vers la connexion...');
        }

        final roleAsync = ref.watch(userRoleProvider);
        return roleAsync.when(
          data: (role) {
            if (role == AppRoles.etudiant) {
              _goTo(context, '/etudiant');
            } else if (role == AppRoles.secretaire) {
              _goTo(context, '/secretaire');
            } else if (role == AppRoles.admin) {
              _goTo(context, '/admin');
            } else {
              _goTo(context, '/login');
            }

            return const _SplashBody(
              message: 'Chargement de votre espace sécurisé...',
            );
          },
          loading: () => const _SplashBody(
            message: 'Vérification de votre profil utilisateur...',
          ),
          error: (error, stackTrace) {
            _goTo(context, '/login');
            return _SplashBody(
              message: 'Impossible de récupérer votre rôle utilisateur.',
              isError: true,
            );
          },
        );
      },
      loading: () => const _SplashBody(
        message: 'Initialisation du système de paiement...',
      ),
      error: (error, stackTrace) => const _SplashBody(
        message: 'Une erreur est survenue lors de l’initialisation.',
        isError: true,
      ),
    );
  }

  void _goTo(BuildContext context, String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(path);
      }
    });
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isError ? Icons.error_outline : Icons.account_balance_wallet,
                size: 72,
                color: isError ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'UATM GASA Formation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (!isError) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
