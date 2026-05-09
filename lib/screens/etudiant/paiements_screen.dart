import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/finance/paiement.dart';
import '../../models/finance/inscription.dart';
import '../../providers/auth_provider.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/etudiant_provider.dart';
import '../../core/constants/status.dart';
import '../shared/finance_widgets.dart';

class PaiementsScreen extends ConsumerStatefulWidget {
  const PaiementsScreen({super.key});

  @override
  ConsumerState<PaiementsScreen> createState() => _PaiementsScreenState();
}

class _PaiementsScreenState extends ConsumerState<PaiementsScreen> {
  final _formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final paiementsAsync = ref.watch(paiementsEtudiantProvider(user.uid));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Paiements'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: () => _showPaymentForm(context),
            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: paiementsAsync.when(
        data: (paiements) {
          if (paiements.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paiements.length,
            itemBuilder: (context, index) => PaiementCard(paiement: paiements[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentForm(context),
        label: const Text('Nouveau paiement'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun paiement enregistré',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Effectuez votre premier versement pour\ncommencer votre inscription.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showPaymentForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PaymentFormSheet(),
    );
  }
}

class _PaymentFormSheet extends ConsumerStatefulWidget {
  const _PaymentFormSheet();

  @override
  ConsumerState<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  ModePaiement _selectedMode = ModePaiement.mobileMoney;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _montantController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Demander un paiement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Montant à payer (FCFA)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montantController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ex: 50000',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Entrez un montant';
                  if (double.tryParse(value) == null) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Moyen de paiement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModeCard(ModePaiement.mobileMoney, 'Mobile Money', Icons.phone_android, Colors.orange),
                  _buildModeCard(ModePaiement.carte, 'Carte', Icons.credit_card, Colors.blue),
                  _buildModeCard(ModePaiement.virement, 'Virement', Icons.account_balance, Colors.purple),
                  _buildModeCard(ModePaiement.especes, 'Espèces', Icons.payments, Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              if (_selectedMode == ModePaiement.mobileMoney) ...[
                const Text(
                  'Numéro de téléphone / Transaction ID',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    hintText: 'Ex: +229 97 00 00 00',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ce champ est obligatoire pour Mobile Money';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Note (Optionnel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ajouter une précision...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(
                              _selectedMode == ModePaiement.mobileMoney ? 'Traitement en cours...' : 'Envoi en cours...',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          _selectedMode == ModePaiement.mobileMoney ? 'Payer maintenant' : 'Soumettre la demande',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(ModePaiement mode, String label, IconData icon, Color color) {
    bool isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
            ),
            child: Icon(icon, color: isSelected ? color : Colors.grey[400], size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw 'Utilisateur non connecté';
      
      final Inscription? inscription = await ref.read(activeInscriptionProvider(user.uid).future);

      if (inscription == null) {
        throw 'Aucune inscription active trouvée.';
      }

      bool success = false;
      String successMessage = '';

      if (_selectedMode == ModePaiement.mobileMoney) {
        // Nouveau flux "réel" pour Mobile Money
        success = await ref.read(paiementServiceProvider).effectuerPaiementMobileMoney(
              inscriptionId: inscription.id,
              etudiantId: user.uid,
              montant: double.parse(_montantController.text),
              telephone: _referenceController.text,
              note: _noteController.text.isNotEmpty ? _noteController.text : null,
            );
        successMessage = 'Paiement Mobile Money effectué et validé avec succès !';
      } else {
        // Flux classique de demande pour les autres modes
        success = await ref.read(paiementServiceProvider).demanderPaiement(
              inscriptionId: inscription.id,
              etudiantId: user.uid,
              montant: double.parse(_montantController.text),
              mode: _selectedMode.toString().split('.').last,
              referencePaiement: _referenceController.text.isNotEmpty ? _referenceController.text : null,
              note: _noteController.text.isNotEmpty ? _noteController.text : null,
            );
        successMessage = 'Demande de paiement envoyée avec succès !';
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw 'Erreur lors de l\'opération.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
