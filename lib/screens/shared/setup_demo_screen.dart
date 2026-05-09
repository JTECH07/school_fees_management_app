import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/demo_provider.dart';
import '../../services/demo_setup_service.dart';

class SetupDemoScreen extends ConsumerStatefulWidget {
  const SetupDemoScreen({super.key});

  @override
  ConsumerState<SetupDemoScreen> createState() => _SetupDemoScreenState();
}

class _SetupDemoScreenState extends ConsumerState<SetupDemoScreen> {
  bool _isLoading = false;
  DemoSetupResult? _result;
  String? _error;

  Future<void> _setup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(demoSetupServiceProvider).setupDemoData();
      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration de démonstration')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cette action prépare des comptes Firebase Auth, les profils Firestore, une filière, une année académique, une inscription, les 5 échéances, ainsi qu’un premier paiement de démonstration.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _setup,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(
              _isLoading
                  ? 'Configuration en cours...'
                  : 'Créer les comptes et données de démo',
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          if (_result != null) ...<Widget>[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_result!.message),
              ),
            ),
            const SizedBox(height: 16),
            ..._result!.accounts.map(
              (account) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(account.description),
                  subtitle: Text(
                    'Email: ${account.email}\nMot de passe: ${account.password}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
