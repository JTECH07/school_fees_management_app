import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/rapport_provider.dart';

class RapportsScreen extends ConsumerWidget {
  const RapportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(rapportFinancierGlobalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports financiers')),
      body: reportAsync.when(
        data: (report) {
          final formatter = NumberFormat.currency(
            locale: 'fr_FR',
            symbol: 'FCFA',
            decimalDigits: 0,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _ReportCard(
                title: 'Total frais',
                value: formatter.format(report['totalFrais'] ?? 0),
              ),
              _ReportCard(
                title: 'Total payé',
                value: formatter.format(report['totalPaye'] ?? 0),
              ),
              _ReportCard(
                title: 'Solde global',
                value: formatter.format(report['soldeGlobal'] ?? 0),
              ),
              _ReportCard(
                title: 'Montant en retard',
                value: formatter.format(report['totalRetard'] ?? 0),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
