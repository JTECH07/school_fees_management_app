// lib/services/recu_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/finance/recu.dart';
import '../models/finance/paiement.dart';
import '../models/user/etudiant.dart';
import '../models/finance/inscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class RecuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Uint8List> generatePdfRecu({
    required Recu recu,
    required Paiement paiement,
    required Etudiant etudiant,
    required Inscription inscription,
  }) async {
    final pdf = pw.Document();

    // Charger le logo UATM (assumant qu'il est dans assets/images/uatm_logo.png)
    final ByteData bytes = await rootBundle.load('assets/images/uatm_logo.png');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logo, width: 80, height: 80),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'UATM GASA Formation',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'BP: 01 BP 1030 Cotonou, Bénin',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Tél: +229 21 30 30 30',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Email: info@uatm.bj',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text(
                  'REÇU DE PAIEMENT N° ${recu.numero}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              pw.Text(
                'Date de génération: ${DateFormat('dd/MM/yyyy HH:mm').format(recu.dateGeneration)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Informations Étudiant',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Divider(),
                    pw.Text('Nom complet: ${etudiant.nomComplet}'),
                    pw.Text('Matricule: ${etudiant.matricule ?? 'N/A'}'),
                    pw.Text('Filière: ${inscription.filiereId}'),
                    pw.Text('Niveau: ${inscription.niveau}'),
                    pw.Text('Année Académique: ${inscription.anneeAcademique}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Détails du Paiement',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Divider(),
                    pw.Text(
                      'Montant payé: ${formatter.format(paiement.montant)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Mode de paiement: ${_modePaiementToString(paiement.mode)}',
                    ),
                    pw.Text(
                      'Date du paiement: ${DateFormat('dd/MM/yyyy HH:mm').format(paiement.date)}',
                    ),
                    if (paiement.note != null && paiement.note!.isNotEmpty)
                      pw.Text('Note: ${paiement.note}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Signature de la Secrétaire',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(width: 100, height: 1, color: PdfColors.black),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre paiement !',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  String _modePaiementToString(ModePaiement mode) {
    switch (mode) {
      case ModePaiement.mobileMoney:
        return 'Mobile Money';
      case ModePaiement.especes:
        return 'Espèces';
      case ModePaiement.virement:
        return 'Virement bancaire';
      case ModePaiement.carte:
        return 'Carte bancaire';
    }
  }

  // Méthode pour sauvegarder et ouvrir le PDF
  Future<void> saveAndOpenPdf(Uint8List pdfBytes, String filename) async {
    // Sur le Web, getTemporaryDirectory n'est pas supporté.
    // Printing.layoutPdf fonctionne sur toutes les plateformes pour l'aperçu/impression/téléchargement.
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: filename,
    );
  }

  // Méthode pour mettre à jour le document Recu avec l'URL du PDF (si stockage cloud)
  Future<void> updateRecuPdfUrl(String recuId, String pdfUrl) async {
    await _firestore
        .collection(AppConstants.recusCollection)
        .doc(recuId)
        .update({'pdfUrl': pdfUrl, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
