import 'bootstrap.dart';
import 'core/config/env_config.dart';

/// Default entry point — runs dev flavor.
/// For flavor-specific builds, use:
///   flutter run --flavor dev -t lib/main_dev.dart
///   flutter run --flavor staging -t lib/main_staging.dart
///   flutter run --flavor production -t lib/main_prod.dart
void main() => bootstrap(environment: Environment.dev);
