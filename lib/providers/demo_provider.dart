import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/demo_setup_service.dart';

final demoSetupServiceProvider = Provider<DemoSetupService>(
  (ref) => DemoSetupService(),
);
