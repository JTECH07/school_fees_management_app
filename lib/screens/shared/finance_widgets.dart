import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance/paiement.dart';
import '../../models/finance/recu.dart';
import '../../core/constants/status.dart';

class PaiementCard extends StatelessWidget {
  final Paiement paiement;
  final String? studentName;
  const PaiementCard({super.key, required this.paiement, this.studentName});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (paiement.statut) {
      case StatutPaiement.valide:
        statusColor = Colors.green;
        statusText = 'Validé';
        statusIcon = Icons.check_circle;
        break;
      case StatutPaiement.refuse:
        statusColor = Colors.red;
        statusText = 'Refusé';
        statusIcon = Icons.cancel;
        break;
      case StatutPaiement.enAttente:
      default:
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.access_time_filled;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (studentName != null) ...[
                      Text(
                        studentName!,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      formatter.format(paiement.montant),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(paiement.date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(_getModeIcon(paiement.mode), size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  _getModeLabel(paiement.mode),
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (paiement.referencePaiement != null) ...[
              const SizedBox(height: 4),
              Text(
                'Réf: ${paiement.referencePaiement}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            if (paiement.statut == StatutPaiement.refuse && paiement.motifRefus != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Motif du refus:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paiement.motifRefus!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(ModePaiement mode) {
    switch (mode) {
      case ModePaiement.mobileMoney: return Icons.phone_android;
      case ModePaiement.carte: return Icons.credit_card;
      case ModePaiement.virement: return Icons.account_balance;
      case ModePaiement.especes: return Icons.payments;
    }
  }

  String _getModeLabel(ModePaiement mode) {
    switch (mode) {
      case ModePaiement.mobileMoney: return 'Mobile Money';
      case ModePaiement.carte: return 'Carte Bancaire';
      case ModePaiement.virement: return 'Virement';
      case ModePaiement.especes: return 'Espèces';
    }
  }
}

class RecuCard extends StatelessWidget {
  final Recu recu;
  final String? studentName;
  final VoidCallback? onDownload;
  final bool isDownloading;

  const RecuCard({
    super.key, 
    required this.recu, 
    this.studentName,
    this.onDownload,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.blue),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (studentName != null) ...[
              Text(
                studentName!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Reçu N° ${recu.numero}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Montant: ${formatter.format(recu.montant)}',
              style: const TextStyle(color: Colors.black87),
            ),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy').format(recu.dateGeneration)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: onDownload != null
            ? (isDownloading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    onPressed: onDownload,
                  ))
            : null,
      ),
    );
  }
}
