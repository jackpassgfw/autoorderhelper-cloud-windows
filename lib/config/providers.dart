import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'environment.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return AppEnvironment.resolve();
});
