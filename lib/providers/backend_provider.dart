import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backend_test_service.dart';

final backendTestServiceProvider = Provider<BackendTestService>(
  (ref) => BackendTestService(),
);
