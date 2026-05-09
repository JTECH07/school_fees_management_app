import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../shared/role_scaffold.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleScaffold(
      title: 'Espace Administrateur',
      subtitle: 'Gérez les utilisateurs, les filières et les inscriptions.',
      accentColor: Colors.red.shade700,
      onLogout: () async {
        await ref.read(authServiceProvider).logout();
        if (context.mounted) {
          context.go('/login');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DashboardCard(
                title: 'Valider Inscriptions',
                icon: Icons.how_to_reg,
                onTap: () => context.go('/admin/validation-inscriptions'),
              ),
              _DashboardCard(
                title: 'Gérer Utilisateurs',
                icon: Icons.people,
                onTap: () => context.go(
                  '/admin/utilisateurs',
                ), // Assumant que cette route existe
              ),
              _DashboardCard(
                title: 'Gérer Filières & Frais',
                icon: Icons.school,
                onTap: () => context.go(
                  '/admin/filieres',
                ), // Assumant que cette route existe
              ),
              _DashboardCard(
                title: 'Consulter Rapports',
                icon: Icons.analytics,
                onTap: () => context.go(
                  '/admin/rapports',
                ), // Assumant que cette route existe
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
