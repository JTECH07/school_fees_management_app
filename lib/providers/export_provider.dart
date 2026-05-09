import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/export_service.dart';
import '../services/recu_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

final recuServiceProvider = Provider<RecuService>((ref) => RecuService());
