import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/etudiant_provider.dart';
import '../shared/finance_widgets.dart';

class HistoriqueSecretaireScreen extends ConsumerWidget {
  const HistoriqueSecretaireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Historique Global'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Paiements', icon: Icon(Icons.payments_outlined)),
              Tab(text: 'Reçus', icon: Icon(Icons.receipt_long_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoriquePaiementsTab(),
            _HistoriqueRecusTab(),
          ],
        ),
      ),
    );
  }
}

class _HistoriquePaiementsTab extends ConsumerWidget {
  const _HistoriquePaiementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paiementsAsync = ref.watch(paiementsProvider);
    final etudiantsAsync = ref.watch(allEtudiantsProvider);

    return paiementsAsync.when(
      data: (paiements) {
        if (paiements.isEmpty) return const Center(child: Text('Aucun paiement enregistré.'));
        
        return etudiantsAsync.when(
          data: (etudiants) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paiements.length,
              itemBuilder: (context, index) {
                final p = paiements[index];
                final etudiant = etudiants.firstWhere((e) => e.id == p.etudiantId, orElse: () => null as dynamic);
                return PaiementCard(
                  paiement: p,
                  studentName: etudiant?.nomComplet ?? 'ID: ${p.etudiantId}',
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _HistoriqueRecusTab extends ConsumerWidget {
  const _HistoriqueRecusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recusAsync = ref.watch(allRecusProvider);
    final etudiantsAsync = ref.watch(allEtudiantsProvider);

    return recusAsync.when(
      data: (recus) {
        if (recus.isEmpty) return const Center(child: Text('Aucun reçu délivré.'));

        return etudiantsAsync.when(
          data: (etudiants) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recus.length,
              itemBuilder: (context, index) {
                final r = recus[index];
                final etudiant = etudiants.firstWhere((e) => e.id == r.etudiantId, orElse: () => null as dynamic);
                return RecuCard(
                  recu: r,
                  studentName: etudiant?.nomComplet ?? 'ID: ${r.etudiantId}',
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}
