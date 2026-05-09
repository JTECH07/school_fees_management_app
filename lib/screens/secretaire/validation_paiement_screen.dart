import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/finance/paiement.dart';
import '../../models/user/etudiant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/etudiant_provider.dart';
import '../../core/constants/status.dart';

class ValidationPaiementScreen extends ConsumerWidget {
  const ValidationPaiementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paiementsAsync = ref.watch(pendingPaiementsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Validation des Paiements'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: paiementsAsync.when(
        data: (paiements) {
          if (paiements.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: paiements.length,
            itemBuilder: (context, index) => _PaiementValidationCard(paiement: paiements[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[100]),
          const SizedBox(height: 16),
          Text(
            'Aucun paiement à valider',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes les demandes ont été traitées.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _PaiementValidationCard extends ConsumerStatefulWidget {
  final Paiement paiement;
  const _PaiementValidationCard({required this.paiement});

  @override
  ConsumerState<_PaiementValidationCard> createState() => _PaiementValidationCardState();
}

class _PaiementValidationCardState extends ConsumerState<_PaiementValidationCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final etudiantAsync = ref.watch(etudiantProvider(widget.paiement.etudiantId));
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            etudiantAsync.when(
              data: (etudiant) => Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Text(etudiant?.nom[0].toUpperCase() ?? '?', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          etudiant?.nomComplet ?? 'Étudiant inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'ID: ${widget.paiement.etudiantId}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur chargement étudiant'),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetail('Montant', formatter.format(widget.paiement.montant), isBold: true),
                _buildDetail('Mode', _getModeLabel(widget.paiement.mode)),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.paiement.referencePaiement != null)
              _buildDetail('Référence / Téléphone', widget.paiement.referencePaiement!),
            if (widget.paiement.note != null) ...[
              const SizedBox(height: 16),
              const Text('Note de l\'étudiant:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(widget.paiement.note!, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _refuser,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _valider,
                    icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  String _getModeLabel(ModePaiement mode) {
    switch (mode) {
      case ModePaiement.mobileMoney: return 'Mobile Money';
      case ModePaiement.carte: return 'Carte';
      case ModePaiement.virement: return 'Virement';
      case ModePaiement.especes: return 'Espèces';
    }
  }

  Future<void> _valider() async {
    setState(() => _isLoading = true);
    try {
      final secretaireId = ref.read(currentUserIdProvider);
      final ok = await ref.read(paiementServiceProvider).validerPaiement(
        paiementId: widget.paiement.id,
        secretaireId: secretaireId!,
      );
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement validé avec succès.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refuser() async {
    final controller = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif de refus'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Motif')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Confirmer le refus')),
        ],
      ),
    );

    if (motif == null || motif.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final secretaireId = ref.read(currentUserIdProvider);
      final ok = await ref.read(paiementServiceProvider).refuserPaiement(
        paiementId: widget.paiement.id,
        secretaireId: secretaireId!,
        motifRefus: motif,
      );
      if (mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paiement refusé.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
