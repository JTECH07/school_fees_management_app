import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_provider.dart';
import '../../providers/filiere_provider.dart';

class GestionAnneesScreen extends ConsumerStatefulWidget {
  const GestionAnneesScreen({super.key});

  @override
  ConsumerState<GestionAnneesScreen> createState() => _GestionAnneesScreenState();
}

class _GestionAnneesScreenState extends ConsumerState<GestionAnneesScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _ajouterAnnee() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminServiceProvider).ajouterAnneeAcademique(_controller.text.trim());
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Année ajoutée !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anneesAsync = ref.watch(anneesAcademiquesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Années Académiques')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle année (ex: 2026-2027)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _ajouterAnnee,
                  child: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: anneesAsync.when(
                data: (annees) => ListView.builder(
                  itemCount: annees.length,
                  itemBuilder: (context, index) {
                    final annee = annees[index];
                    return Card(
                      child: ListTile(
                        title: Text(annee.libelle),
                        trailing: Icon(
                          annee.estFermee ? Icons.lock_outline : Icons.lock_open,
                          color: annee.estFermee ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
