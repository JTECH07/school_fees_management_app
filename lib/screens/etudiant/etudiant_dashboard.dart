import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uatm_paiements/core/constants/status.dart';

import '../../models/finance/echeance.dart';
import '../../models/finance/paiement.dart';
import '../../models/finance/recu.dart';
import '../../models/user/etudiant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/etudiant_provider.dart';
import '../../screens/shared/role_scaffold.dart';
import '../../datasources/remote/firebase/firestore_service.dart'; // Import FirestoreService

class EtudiantDashboard extends ConsumerWidget {
  const EtudiantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etudiantAsync = ref.watch(currentEtudiantProvider);

    return etudiantAsync.when(
      data: (etudiant) {
        if (etudiant == null) {
          return RoleScaffold(
            title: 'Espace étudiant',
            subtitle: 'Profil étudiant introuvable pour cet utilisateur.',
            accentColor: const Color(0xFF0B5CAD),
            onLogout: () => _logout(context, ref),
            child: const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucun profil étudiant n’a encore été créé. Passe par la configuration de démonstration ou ajoute ce profil dans Firestore.',
                ),
              ),
            ),
          );
        }

        return _StudentContent(
          etudiant: etudiant,
          onLogout: () => _logout(context, ref),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur de chargement du profil étudiant: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}

class _StudentContent extends ConsumerWidget {
  const _StudentContent({required this.etudiant, required this.onLogout});

  final Etudiant etudiant;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inscriptionAsync = ref.watch(activeInscriptionProvider(etudiant.id));
    final paiementsAsync = ref.watch(paiementsEtudiantProvider(etudiant.id));
    final recusAsync = ref.watch(recusEtudiantProvider(etudiant.id));

    return RoleScaffold(
      title: 'Espace étudiant',
      subtitle:
          'Consultez votre solde, vos échéances, vos paiements et vos reçus.',
      accentColor: const Color(0xFF0B5CAD),
      onLogout: onLogout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ProfileCard(etudiant: etudiant),
          const SizedBox(height: 16),
          inscriptionAsync.when(
            data: (inscription) {
              if (inscription == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aucune inscription active trouvée pour cet étudiant.',
                    ),
                  ),
                );
              }

              final echeancesAsync = ref.watch(
                echeancesInscriptionProvider(inscription.id),
              );

              return paiementsAsync.when(
                data: (paiements) {
                  final totalPaye = paiements
                      .where((p) => p.statut == StatutPaiement.valide)
                      .fold<double>(0, (sum, p) => sum + p.montant);
                  final solde = inscription.fraisTotal - totalPaye;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _StatCard(
                            label: 'Frais totaux',
                            value: _currency(inscription.fraisTotal),
                            color: const Color(0xFF0B5CAD),
                          ),
                          _StatCard(
                            label: 'Total payé',
                            value: _currency(totalPaye),
                            color: const Color(0xFF2E8B57),
                          ),
                          _StatCard(
                            label: 'Solde',
                            value: _currency(solde),
                            color: const Color(0xFFE07A00),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: Text(
                            'Inscription ${inscription.anneeAcademique} - ${inscription.niveau}',
                          ),
                          subtitle: Text(
                            'Filière: ${inscription.filiereId} • Statut: ${inscription.statut}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Échéances',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      echeancesAsync.when(
                        data: (echeances) => Column(
                          children: echeances
                              .map((e) => _EcheanceCard(echeance: e))
                              .toList(),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Text('$error'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historique des paiements',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/etudiant/paiements'),
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (paiements.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Aucun paiement enregistré pour le moment.',
                            ),
                          ),
                        )
                      else
                        ...paiements.map((paiement) => _PaiementTile(paiement)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reçus',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/etudiant/recus'),
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      recusAsync.when(
                        data: (recus) => recus.isEmpty
                            ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Aucun reçu disponible.'),
                                ),
                              )
                            : Column(
                                children: recus
                                    .map((recu) => _RecuTile(recu))
                                    .toList(),
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Text('$error'),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Text('$error'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('$error'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.etudiant});

  final Etudiant etudiant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              etudiant.nomComplet,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Matricule: ${etudiant.matricule}'),
            Text('Email: ${etudiant.email}'),
            Text('Téléphone: ${etudiant.telephone}'),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EcheanceCard extends StatelessWidget {
  const _EcheanceCard({required this.echeance});

  final Echeance echeance;

  @override
  Widget build(BuildContext context) {
    final progress = (echeance.montantPaye / echeance.montant).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Échéance ${echeance.numero}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(_statusLabel(echeance.statut)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date limite: ${DateFormat('dd/MM/yyyy').format(echeance.dateLimite)}',
            ),
            Text('Montant: ${_currency(echeance.montant)}'),
            Text('Payé: ${_currency(echeance.montantPaye)}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

class _PaiementTile extends StatelessWidget {
  const _PaiementTile(this.paiement);

  final Paiement paiement;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.payments_outlined),
        title: Text(_currency(paiement.montant)),
        subtitle: Text(
          '${_modeLabel(paiement.mode)} • ${DateFormat('dd/MM/yyyy').format(paiement.date)}',
        ),
        trailing: Text(_paiementStatusLabel(paiement.statut)),
      ),
    );
  }
}

class _RecuTile extends StatelessWidget {
  const _RecuTile(this.recu);

  final Recu recu;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(recu.numero),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy').format(recu.dateGeneration)} • ${_currency(recu.montant)}',
        ),
      ),
    );
  }
}

String _currency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  return formatter.format(value);
}

String _statusLabel(StatutEcheance statut) {
  switch (statut) {
    case StatutEcheance.payee:
      return 'Payée';
    case StatutEcheance.retard:
      return 'En retard';
    case StatutEcheance.aPayer:
      return 'À payer';
  }
}

String _paiementStatusLabel(StatutPaiement statut) {
  switch (statut) {
    case StatutPaiement.valide:
      return 'Validé';
    case StatutPaiement.refuse:
      return 'Refusé';
    case StatutPaiement.enAttente:
      return 'En attente';
  }
}

String _modeLabel(ModePaiement mode) {
  switch (mode) {
    case ModePaiement.especes:
      return 'Espèces';
    case ModePaiement.mobileMoney:
      return 'Mobile Money';
    case ModePaiement.carte:
      return 'Carte';
    case ModePaiement.virement:
      return 'Virement';
  }
}
