import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/backend_provider.dart';
import '../../services/backend_test_service.dart';

class BackendTestScreen extends ConsumerStatefulWidget {
  const BackendTestScreen({super.key});

  @override
  ConsumerState<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends ConsumerState<BackendTestScreen> {
  bool _isLoading = false;
  List<BackendCheckResult> _results = <BackendCheckResult>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runChecks();
    });
  }

  Future<void> _runChecks() async {
    setState(() {
      _isLoading = true;
      _results = <BackendCheckResult>[];
    });

    final service = ref.read(backendTestServiceProvider);
    final results = <BackendCheckResult>[
      service.checkFirebaseInitialization(),
      service.checkAuthState(),
      await service.checkFirestore(),
      await service.checkRealtimeDatabase(),
    ];

    if (!mounted) {
      return;
    }

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(backendTestServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Test du backend Firebase')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Configuration détectée',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Projet Firebase: ${service.projectId}'),
                  const SizedBox(height: 4),
                  Text(
                    service.realtimeDatabaseUrl.isEmpty
                        ? 'URL Realtime Database: non détectée'
                        : 'URL Realtime Database: ${service.realtimeDatabaseUrl}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _runChecks,
            icon: const Icon(Icons.cloud_done_outlined),
            label: Text(
              _isLoading ? 'Tests en cours...' : 'Lancer les tests backend',
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_results.isEmpty)
            const Text('Aucun test exécuté pour le moment.')
          else
            ..._results.map(_ResultCard.new),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Astuce: si Realtime Database échoue alors que Firestore fonctionne, crée d’abord la base RTDB dans la console Firebase puis lance l’application avec --dart-define=FIREBASE_DATABASE_URL=https://votre-url.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(this.result);

  final BackendCheckResult result;

  @override
  Widget build(BuildContext context) {
    final Color color = result.success ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Icon(result.success ? Icons.check : Icons.close),
        ),
        title: Text(result.service),
        subtitle: Text(result.message),
      ),
    );
  }
}
