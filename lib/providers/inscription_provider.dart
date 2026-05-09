import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/inscription_service.dart';

final inscriptionServiceProvider = Provider<InscriptionService>(
  (ref) => InscriptionService(),
);
