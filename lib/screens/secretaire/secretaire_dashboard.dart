import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uatm_paiements/core/constants/status.dart';
import 'package:uatm_paiements/core/constants/app_constants.dart';

import '../../models/user/etudiant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/etudiant_provider.dart';
import '../../providers/paiement_provider.dart';
// Import PaiementService
import '../shared/role_scaffold.dart';

class SecretaireDashboard extends ConsumerStatefulWidget {
  const SecretaireDashboard({super.key});

  @override
  ConsumerState<SecretaireDashboard> createState() =>
      _SecretaireDashboardState();
}

class _SecretaireDashboardState extends ConsumerState<SecretaireDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  String _selectedMode = 'mobileMoney';
  String _search = '';
  Etudiant? _selectedEtudiant;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etudiantsAsync = ref.watch(allEtudiantsProvider);

    return RoleScaffold(
      title: 'Espace secrétaire',
      subtitle:
          'Recherchez un étudiant, suivez son solde et enregistrez un paiement.',
      accentColor: const Color(0xFFE07A00),
      onLogout: () async {
        await ref.read(authServiceProvider).logout();
        if (context.mounted) {
          context.go('/login');
        }
      },
      actions: <Widget>[
        IconButton(
          onPressed: () => context.go('/secretaire/retards'),
          icon: const Icon(Icons.warning_amber_outlined),
          tooltip: 'Échéances en retard',
        ),
        IconButton(
          onPressed: () => context.go('/secretaire/rapports'),
          icon: const Icon(Icons.assessment_outlined),
          tooltip: 'Rapports',
        ),
        IconButton(
          onPressed: () => context.push('/secretaire/historique'),
          icon: const Icon(Icons.history),
          tooltip: 'Historique',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => context.go('/secretaire/retards'),
                icon: const Icon(Icons.warning_amber_outlined),
                label: const Text('Voir les retards'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/secretaire/rapports'),
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('Voir les rapports'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/secretaire/historique'),
                icon: const Icon(Icons.history),
                label: const Text('Voir l\'historique'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher par matricule, nom ou prénom',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _search = value.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          etudiantsAsync.when(
            data: (etudiants) {
              final filtered = etudiants.where((e) {
                if (_search.isEmpty) {
                  return true;
                }

                final haystack = '${e.matricule} ${e.nom} ${e.prenom}'
                    .toLowerCase();
                return haystack.contains(_search);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Étudiants',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucun étudiant trouvé.'),
                      ),
                    )
                  else
                    ...filtered.map(
                      (etudiant) => Card(
                        child: ListTile(
                          selected: _selectedEtudiant?.id == etudiant.id,
                          leading: const Icon(Icons.person_outline),
                          title: Text(etudiant.nomComplet),
                          subtitle: Text(
                            '${etudiant.matricule} • ${etudiant.telephone}',
                          ),
                          onTap: () {
                            setState(() {
                              _selectedEtudiant = etudiant;
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_selectedEtudiant != null)
                    _SelectedStudentPanel(
                      etudiant: _selectedEtudiant!,
                      montantController: _montantController,
                      selectedMode: _selectedMode,
                      isSubmitting: _isSubmitting,
                      onModeChanged: (value) {
                        setState(() {
                          _selectedMode = value;
                        });
                      },
                      onSubmit: _submitPayment,
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Paiements en attente de validation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _PendingPaymentsList(), // Nouveau widget pour les paiements en attente
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Erreur: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    final selectedEtudiant = _selectedEtudiant;
    if (selectedEtudiant == null) {
      return;
    }

    final montant = double.tryParse(
      _montantController.text.trim().replaceAll(',', '.'),
    );
    if (montant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Montant invalide.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final inscription = await ref
          .read(firestoreServiceProvider)
          .getInscriptionActiveEtudiant(selectedEtudiant.id)
          .first;
      final secretaireId = ref.read(currentUserIdProvider);

      if (inscription == null || secretaireId == null) {
        throw StateError(
          'Inscription active ou utilisateur secrétaire absent.',
        );
      }

      final success = await ref
          .read(paiementServiceProvider)
          .enregistrerPaiementParSecretaire(
            inscriptionId: inscription.id,
            etudiantId: selectedEtudiant.id,
            secretaireId: secretaireId,
            montant: montant,
            mode: _selectedMode,
          );

      if (!mounted) {
        return;
      }

      if (success) {
        _montantController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré avec succès.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le paiement n’a pas pu être enregistré.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _SelectedStudentPanel extends ConsumerWidget {
  const _SelectedStudentPanel({
    required this.etudiant,
    required this.montantController,
    required this.selectedMode,
    required this.isSubmitting,
    required this.onModeChanged,
    required this.onSubmit,
  });

  final Etudiant etudiant;
  final TextEditingController montantController;
  final String selectedMode;
  final bool isSubmitting;
  final ValueChanged<String> onModeChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inscriptionAsync = ref.watch(activeInscriptionProvider(etudiant.id));
    final paiementsAsync = ref.watch(paiementsEtudiantProvider(etudiant.id));

    return inscriptionAsync.when(
      data: (inscription) {
        if (inscription == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cet étudiant n’a pas d’inscription active.'),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          etudiant.nomComplet,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Matricule: ${etudiant.matricule}'),
                        Text('Inscription: ${inscription.anneeAcademique}'),
                        Text('Total payé: ${_currency(totalPaye)}'),
                        Text('Solde: ${_currency(solde)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: montantController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Montant à enregistrer',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedMode,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'mobileMoney',
                              child: Text('Mobile Money'),
                            ),
                            DropdownMenuItem(
                              value: 'especes',
                              child: Text('Espèces'),
                            ),
                            DropdownMenuItem(
                              value: 'virement',
                              child: Text('Virement'),
                            ),
                            DropdownMenuItem(
                              value: 'carte',
                              child: Text('Carte'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              onModeChanged(value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Mode de paiement',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : onSubmit,
                            child: Text(
                              isSubmitting
                                  ? 'Enregistrement...'
                                  : 'Enregistrer le paiement',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Échéances actuelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                echeancesAsync.when(
                  data: (echeances) => Column(
                    children: echeances
                        .map(
                          (e) => Card(
                            child: ListTile(
                              title: Text('Échéance ${e.numero}'),
                              subtitle: Text(
                                'Reste: ${_currency(e.montantRestant.clamp(0, e.montant))}',
                              ),
                              trailing: Text(_statusLabel(e.statut)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text('$error'),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('$error'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('$error'),
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

String _modeLabel(String mode) {
  switch (mode) {
    case 'mobileMoney':
      return 'Mobile Money';
    case 'especes':
      return 'Espèces';
    case 'virement':
      return 'Virement';
    case 'carte':
      return 'Carte';
    default:
      return 'Mode inconnu';
  }
}

class _PendingPaymentsList extends ConsumerWidget {
  const _PendingPaymentsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPaymentsAsync = ref.watch(
      pendingPaiementsProvider,
    ); // Utilise le nouveau provider

    return pendingPaymentsAsync.when(
      data: (paiements) {
        if (paiements.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun paiement en attente de validation.'),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paiements.length,
          itemBuilder: (context, index) {
            final paiement = paiements[index];
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection(AppConstants.etudiantsCollection)
                  .doc(paiement.etudiantId)
                  .get(),
              builder:
                  (
                    context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                    snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return const Text('Erreur de chargement de l\'étudiant.');
                    }
                    final etudiant = Etudiant.fromFirestore(
                      snapshot.data!.data()!,
                      snapshot.data!.id,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          '${etudiant.nomComplet} - ${_currency(paiement.montant)}',
                        ),
                        subtitle: Text(
                          'Mode: ${_modeLabel(paiement.mode.name)} le ${DateFormat('dd/MM/yyyy').format(paiement.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () =>
                                  _validerPaiement(context, ref, paiement.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () =>
                                  _refuserPaiement(context, ref, paiement.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Erreur: $error'),
    );
  }

  Future<void> _validerPaiement(
    BuildContext context,
    WidgetRef ref,
    String paiementId,
  ) async {
    final secretaireId = ref.read(currentUserIdProvider);
    if (secretaireId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID secrétaire non trouvé.')),
      );
      return;
    }
    try {
      await ref
          .read(paiementServiceProvider)
          .validerPaiement(paiementId: paiementId, secretaireId: secretaireId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement validé avec succès !')),
        );
        ref.invalidate(pendingPaiementsProvider); // Rafraîchir la liste
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de validation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refuserPaiement(
    BuildContext context,
    WidgetRef ref,
    String paiementId,
  ) async {
    final secretaireId = ref.read(currentUserIdProvider);
    if (secretaireId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: ID secrétaire non trouvé.')),
      );
      return;
    }
    final motif = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController motifController = TextEditingController();
        return AlertDialog(
          title: const Text('Refuser le paiement'),
          content: TextFormField(
            controller: motifController,
            decoration: const InputDecoration(labelText: 'Motif du refus'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(motifController.text),
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );
    if (motif != null) {
      try {
        await ref
            .read(paiementServiceProvider)
            .refuserPaiement(
              paiementId: paiementId,
              secretaireId: secretaireId,
              motifRefus: motif,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Paiement refusé.')));
          ref.invalidate(pendingPaiementsProvider); // Rafraîchir la liste
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de refus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
