import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/rapport_provider.dart';

class ConsultationsRapportsScreen extends ConsumerWidget {
  const ConsultationsRapportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(rapportFinancierGlobalProvider);
    final retardAsync = ref.watch(echeancesEnRetardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation des rapports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          reportAsync.when(
            data: (report) {
              final formatter = NumberFormat.currency(
                locale: 'fr_FR',
                symbol: 'FCFA',
                decimalDigits: 0,
              );

              return Column(
                children: <Widget>[
                  _ReportTile(
                    label: 'Total frais',
                    value: formatter.format(report['totalFrais'] ?? 0),
                  ),
                  _ReportTile(
                    label: 'Total payé',
                    value: formatter.format(report['totalPaye'] ?? 0),
                  ),
                  _ReportTile(
                    label: 'Solde global',
                    value: formatter.format(report['soldeGlobal'] ?? 0),
                  ),
                  _ReportTile(
                    label: 'Montants en retard',
                    value: formatter.format(report['totalRetard'] ?? 0),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Erreur: $error'),
          ),
          const SizedBox(height: 16),
          retardAsync.when(
            data: (retards) => Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_outlined),
                title: const Text('Échéances en retard'),
                trailing: Text(
                  retards.length.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => Text('Erreur: $error'),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
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
