import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uatm_paiements/providers/etudiant_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/filiere_provider.dart';
import '../../models/finance/inscription.dart';
import '../../models/user/etudiant.dart';

final pendingInscriptionProvider = FutureProvider.family<Inscription?, String>((ref, etudiantId) {
  return ref.read(firestoreServiceProvider).getPendingInscriptionForEtudiant(etudiantId);
});

class ValidationInscriptionsScreen extends ConsumerWidget {
  const ValidationInscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingStudentsAsync = ref.watch(pendingEtudiantsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/uatm_logo.png', height: 40),
            const SizedBox(width: 12),
            const Text('Validation des inscriptions'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: pendingStudentsAsync.when(
        data: (students) {
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Tout est à jour !',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune inscription en attente de validation.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return ValidationStudentCard(etudiant: students[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class ValidationStudentCard extends ConsumerStatefulWidget {
  final Etudiant etudiant;
  const ValidationStudentCard({super.key, required this.etudiant});

  @override
  ConsumerState<ValidationStudentCard> createState() => _ValidationStudentCardState();
}

class _ValidationStudentCardState extends ConsumerState<ValidationStudentCard> {
  final TextEditingController _fraisController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  String? _selectedAnnee;
  bool _isLoading = false;

  @override
  void dispose() {
    _fraisController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  // Méthode pour pré-remplir les frais
  void _updateFraisAuto() {
    final etudiant = widget.etudiant;
    final filieres = ref.read(filieresProvider).value;
    if (filieres == null) return;

    final filiere = filieres.where((f) => f.id == etudiant.filiereId).firstOrNull;
    if (filiere != null && etudiant.niveau != null) {
      final frais = filiere.fraisParNiveau[etudiant.niveau];
      if (frais != null && _fraisController.text.isEmpty) {
        _fraisController.text = frais.toStringAsFixed(0);
      }
    }
  }

  Future<void> _validerInscription(String? inscriptionId) async {
    if (_fraisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le montant des frais de scolarité.')),
      );
      return;
    }
    
    if (_selectedAnnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une année académique.')),
      );
      return;
    }

    final fraisTotal = double.tryParse(_fraisController.text);
    if (fraisTotal == null || fraisTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant des frais invalide.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).validerInscription(
            etudiantId: widget.etudiant.id,
            inscriptionId: inscriptionId,
            fraisTotal: fraisTotal,
            matricule: _matriculeController.text.trim().isNotEmpty ? _matriculeController.text.trim() : null,
            anneeAcademique: _selectedAnnee,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription validée avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de validation: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refuserInscription() async {
    final TextEditingController motifController = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser l\'inscription'),
        content: TextFormField(
          controller: motifController,
          decoration: const InputDecoration(labelText: 'Motif du refus'),
          autofocus: true,
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
      ),
    );

    if (motif != null && motif.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await ref.read(adminServiceProvider).refuserInscription(widget.etudiant.id, motif);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscription refusée.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de refus: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final etudiant = widget.etudiant;
    final pendingInscriptionAsync = ref.watch(pendingInscriptionProvider(etudiant.id));
    final filieresAsync = ref.watch(filieresProvider);
    final anneesAsync = ref.watch(anneesAcademiquesProvider);

    // Déclencher le pré-remplissage quand les données sont prêtes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFraisAuto();
    });

    String getFiliereCode(String? id) {
      if (id == null) return 'N/A';
      return filieresAsync.when(
        data: (filieres) {
          final filiere = filieres.where((f) => f.id == id).firstOrNull;
          return filiere?.code ?? id;
        },
        loading: () => '...',
        error: (_, __) => id,
      );
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    etudiant.nom.isNotEmpty ? etudiant.nom[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etudiant.nomComplet,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(etudiant.email, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(etudiant.telephone, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'En attente',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            pendingInscriptionAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
              error: (error, stackTrace) => Text('Erreur: $error', style: const TextStyle(color: Colors.red)),
              data: (inscription) {
                // Si l'inscription est nulle, on affiche les infos de base de l'étudiant
                // et on permet la validation qui créera l'inscription.
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de l\'inscription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (inscription == null) 
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Données d\'inscription non initialisées. Elles seront créées lors de la validation.',
                                style: TextStyle(color: Colors.orange[900], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem('Filière', getFiliereCode(inscription?.filiereId ?? etudiant.filiereId)),
                          _buildInfoItem('Niveau', inscription?.niveau ?? etudiant.niveau ?? 'N/A'),
                          _buildInfoItem('Année (Souhaitée)', inscription?.anneeAcademique ?? '2026-2027'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    anneesAsync.when(
                      data: (annees) {
                        final activeYears = annees.where((a) => !a.estFermee).toList();
                        // Initialiser l'année par défaut si non définie
                        if (_selectedAnnee == null && activeYears.isNotEmpty) {
                          _selectedAnnee = activeYears.first.libelle;
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedAnnee,
                          decoration: InputDecoration(
                            labelText: 'Année académique d\'inscription',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: activeYears.map((a) => DropdownMenuItem(value: a.libelle, child: Text(a.libelle))).toList(),
                          onChanged: (v) => setState(() => _selectedAnnee = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erreur années: $e'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _matriculeController,
                      decoration: InputDecoration(
                        labelText: 'Matricule (Optionnel - Laissé vide pour auto-génération)',
                        hintText: 'Ex: GASA-2026-001',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'Laissez vide pour générer automatiquement selon la séquence.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fraisController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Frais de scolarité total (FCFA)',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'Valeur pré-remplie selon la filière et le niveau.',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Veuillez entrer le montant';
                        if (double.tryParse(value) == null) return 'Montant invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _refuserInscription,
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _validerInscription(inscription?.id),
                          icon: _isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check),
                          label: const Text('Valider l\'inscription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
