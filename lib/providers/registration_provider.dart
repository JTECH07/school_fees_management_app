import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/registration_service.dart';

final registrationServiceProvider = Provider<RegistrationService>(
  (ref) => RegistrationService(),
);
