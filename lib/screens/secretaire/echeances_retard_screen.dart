import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/rapport_provider.dart';
import '../../models/finance/echeance.dart';

class EcheancesRetardScreen extends ConsumerWidget {
  const EcheancesRetardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retardAsync = ref.watch(echeancesEnRetardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Échéances en retard')),
      body: retardAsync.when(
        data: (echeances) {
          if (echeances.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucune échéance en retard actuellement.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: echeances
                .map(
                  (e) {
                    final echeance = e['echeance'] as Echeance;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text('Inscription ${echeance.inscriptionId}'),
                        subtitle: Text(
                          'Échéance ${echeance.numero} • limite ${DateFormat('dd/MM/yyyy').format(echeance.dateLimite)}',
                        ),
                        trailing: Text(
                          '${echeance.montantRestant.clamp(0, echeance.montant).toStringAsFixed(0)} FCFA',
                        ),
                      ),
                    );
                  },
                )
                .toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
