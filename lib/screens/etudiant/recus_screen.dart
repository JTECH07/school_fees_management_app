import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/finance/recu.dart';
import '../../providers/auth_provider.dart';
import '../../providers/etudiant_provider.dart';
import '../../services/recu_service.dart';
import '../shared/finance_widgets.dart';

final recuServiceProvider = Provider((ref) => RecuService());

class RecusScreen extends ConsumerWidget {
  const RecusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final recusAsync = ref.watch(recusEtudiantProvider(user.uid));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Reçus'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: recusAsync.when(
        data: (recus) {
          if (recus.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recus.length,
            itemBuilder: (context, index) => _RecuItem(recu: recus[index]),
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun reçu disponible',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos reçus apparaîtront ici une fois que\nvos paiements seront validés.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _RecuItem extends ConsumerStatefulWidget {
  final Recu recu;
  const _RecuItem({required this.recu});

  @override
  ConsumerState<_RecuItem> createState() => _RecuItemState();
}

class _RecuItemState extends ConsumerState<_RecuItem> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final recuService = ref.read(recuServiceProvider);
      
      // Récupérer les données nécessaires pour le PDF
      final paiement = await ref.read(firestoreServiceProvider).getRawPaiement(widget.recu.paiementId);
      final etudiant = await ref.read(firestoreServiceProvider).getRawEtudiant(widget.recu.etudiantId);
      final inscription = await ref.read(firestoreServiceProvider).getRawInscription(widget.recu.inscriptionId);

      if (paiement != null && etudiant != null && inscription != null) {
        final pdfBytes = await recuService.generatePdfRecu(
          recu: widget.recu,
          paiement: paiement,
          etudiant: etudiant,
          inscription: inscription,
        );
        
        await recuService.saveAndOpenPdf(pdfBytes, 'Recu_${widget.recu.numero}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le reçu a été généré avec succès !')),
          );
        }
      } else {
        throw 'Données incomplètes pour générer le PDF.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecuCard(
      recu: widget.recu,
      onDownload: _downloadPdf,
      isDownloading: _isDownloading,
    );
  }
}
