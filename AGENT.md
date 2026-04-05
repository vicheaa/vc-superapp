# VC SuperApp — Agent Reference

> **Read this file first.** It contains everything you need to understand the project structure, architecture, coding style, and conventions. Follow these rules strictly when generating or modifying code.

---

## 1. Project Overview

| Field             | Value                                      |
| ----------------- | ------------------------------------------ |
| **Name**          | `vc_super_app`                             |
| **Type**          | Flutter mobile app (iOS + Android)         |
| **Dart SDK**      | `^3.10.1`                                  |
| **Architecture**  | Feature-first Clean Architecture           |
| **State Mgmt**    | Riverpod (`flutter_riverpod ^3.3.1`)       |
| **DI**            | GetIt (`get_it ^9.2.1`)                    |
| **Routing**       | GoRouter (`go_router ^17.1.0`)             |
| **Networking**    | Dio (`dio ^5.9.2`) with custom interceptors|
| **Local Storage** | Hive, SharedPreferences, FlutterSecureStorage |
| **Firebase**      | Core, Analytics, Crashlytics, Messaging, In-App Messaging, Auth |
| **Build Flavors** | `dev`, `staging`, `production`             |
| **Font**          | Kantumruy Pro (custom, bundled in assets)  |
| **Design System** | Material 3 with custom `AppTheme`, `AppColors`, `AppTextStyles` |

---

## 2. Directory Structure

```
lib/
├── main.dart                  # Default entry point (dev)
├── main_dev.dart              # Dev flavor entry
├── main_staging.dart          # Staging flavor entry
├── main_prod.dart             # Production flavor entry
├── bootstrap.dart             # Shared bootstrap (env, firebase, DI, runApp)
├── app.dart                   # Root MaterialApp.router (ConsumerWidget)
│
├── core/                      # Shared, cross-feature infrastructure
│   ├── config/
│   │   └── env_config.dart    # EnvConfig (reads .env.* via flutter_dotenv)
│   ├── constants/
│   │   ├── api_constants.dart # Timeouts, retry, pagination, headers, endpoints
│   │   └── storage_keys.dart  # String constants for local storage keys
│   ├── di/
│   │   └── injection.dart     # GetIt service locator registration
│   ├── error/
│   │   ├── app_exception.dart # Sealed AppException hierarchy
│   │   ├── error_handler.dart # GlobalErrorHandler (Dio → AppException, Crashlytics)
│   │   └── failure.dart       # Sealed Failure hierarchy (for repository layer)
│   ├── router/
│   │   └── app_router.dart    # GoRouter config (auth redirect, route table)
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── notification_service.dart
│   │   └── popup_service.dart
│   ├── theme/
│   │   ├── app_colors.dart    # Color palette (primary, secondary, neutral, semantic)
│   │   ├── app_text_styles.dart # M3 type scale
│   │   └── app_theme.dart     # Light & dark ThemeData
│   ├── utils/
│   │   ├── helper.dart        # General helpers
│   │   └── logger.dart        # AppLogger (debug, info, warning, error)
│   └── widgets/               # Reusable UI components
│       ├── button.dart        # AppButton (filled, outlined, text, dashed)
│       ├── dialog.dart        # AppAlertDialog, showAppDialog
│       ├── custom_progress_indicator.dart
│       ├── text_input.dart
│       ├── card.dart
│       ├── dropdown_menu.dart
│       ├── bottom_sheet.dart
│       ├── footer.dart
│       ├── image_upload.dart
│       ├── loading.dart
│       └── require_permission.dart
│
├── data/                      # Shared data-layer infrastructure
│   ├── network/
│   │   ├── dio_client.dart    # DioClient factory (interceptors, base config)
│   │   ├── base_api_service.dart  # Abstract BaseApiService (request<T> → ApiResult<T>)
│   │   ├── api_result.dart    # Sealed ApiResult<T> (ApiSuccess / ApiFailure)
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart   # Bearer token + 401 refresh
│   │       ├── cache_interceptor.dart  # GET caching via Hive
│   │       └── retry_interceptor.dart  # Exponential retry
│   ├── local/
│   │   ├── secure_storage.dart  # SecureStorageService (tokens, credentials)
│   │   ├── hive_storage.dart    # HiveStorageService (API cache)
│   │   ├── local_storage.dart   # LocalStorageUtils (SharedPreferences)
│   │   └── path_storage.dart
│   └── dto/
│       └── pagination_response.dart  # Generic PaginatedResponse<T>
│
├── domain/                    # Shared domain-layer base classes
│   └── base/
│       ├── base_view_model.dart  # BaseViewModel (loading, error, safeCall)
│       └── pagination_mixin.dart # PaginationMixin<T>
│
└── features/                  # Feature modules (each follows Clean Arch layers)
    ├── auth/
    │   ├── data/
    │   │   ├── auth_api_service.dart
    │   │   ├── auth_repository_impl.dart
    │   │   └── models/auth_response.dart
    │   ├── domain/
    │   │   ├── auth_repository.dart   # Abstract
    │   │   ├── auth_state.dart
    │   │   └── models/user_model.dart
    │   └── presentation/
    │       ├── controllers/auth_controller.dart  # AsyncNotifier-based
    │       └── screens/
    │           ├── login_screen.dart
    │           └── splash_screen.dart
    ├── home/
    │   └── presentation/
    │       ├── home_provider.dart
    │       ├── home_screen.dart
    │       └── widgets/
    │           ├── home_header.dart
    │           ├── miniapp_grid.dart
    │           └── miniapp_grid_card.dart
    ├── profile/
    │   ├── data/
    │   │   ├── profile_api_service.dart
    │   │   └── profile_repository_impl.dart
    │   ├── domain/
    │   │   ├── profile_repository.dart
    │   │   └── models/profile.dart
    │   └── presentation/
    │       ├── profile_provider.dart
    │       └── profile_screen.dart
    ├── localization/
    │   ├── data/
    │   │   ├── localization_api_service.dart
    │   │   └── localization_service.dart
    │   └── presentation/
    │       ├── localization_provider.dart
    │       └── localization_screen.dart
    ├── miniapps/
    │   ├── data/
    │   │   ├── miniapp_api_service.dart
    │   │   ├── miniapp_repository_impl.dart
    │   │   └── models/miniapp_response.dart
    │   └── domain/
    │       ├── miniapp_repository.dart
    │       └── models/miniapp_manifest.dart
    └── webview/
        └── presentation/
            └── super_app_webview.dart

tools/
└── generate_feature.dart    # Feature scaffolding CLI tool

assets/
├── lang/                    # Translation JSON files (en.json, km.json)
├── icon/                    # App icons
└── fonts/kantumruy/         # Kantumruy Pro font files
```

---

## 3. Architecture & Data Flow

The project follows **Feature-first Clean Architecture** with three layers per feature:

```
┌──────────────────────────────────────────────────┐
│  Presentation Layer                              │
│  (Screens, Widgets, Providers/Notifiers)         │
│  • ConsumerWidget / ConsumerStatefulWidget       │
│  • AsyncNotifierProvider for state               │
│  • Uses `getIt<Repository>()` via DI             │
├──────────────────────────────────────────────────┤
│  Domain Layer                                    │
│  (Abstract Repositories, Models, State classes)  │
│  • Pure Dart, no Flutter imports                 │
│  • Models use `fromJson` factory constructors    │
│  • Repository is abstract (interface)            │
├──────────────────────────────────────────────────┤
│  Data Layer                                      │
│  (API Services, Repository Implementations)      │
│  • ApiService extends BaseApiService             │
│  • RepositoryImpl implements Repository          │
│  • Returns ApiResult<T>, throws Failure          │
└──────────────────────────────────────────────────┘
```

### Data Flow for a typical API call:

```
Screen (ref.watch) → Provider/Notifier → Repository (abstract) → RepositoryImpl → ApiService → BaseApiService.request() → Dio → Server
                                                                                                      ↓
                                                                                               ApiResult<T>
                                                                                          (success or failure)
                                                                                                      ↓
                                                                   RepositoryImpl.when(success: ..., failure: throw NetworkFailure)
                                                                                                      ↓
                                                                              Notifier catches error → updates state
                                                                                                      ↓
                                                                                    Screen reacts via ref.watch()
```

---

## 4. Feature File Structure (Per Feature)

Every feature follows this exact directory layout:

```
lib/features/<feature_name>/
├── data/
│   ├── <feature_name>_api_service.dart      # Extends BaseApiService
│   ├── <feature_name>_repository_impl.dart  # Implements <Feature>Repository
│   └── models/                              # (optional) Data-layer DTOs
│       └── <feature_name>_response.dart
├── domain/
│   ├── <feature_name>_repository.dart       # Abstract repository interface
│   └── models/
│       └── <feature_name>.dart              # Domain model with fromJson
└── presentation/
    ├── <feature_name>_provider.dart          # Riverpod state + notifier
    ├── <feature_name>_screen.dart            # UI (ConsumerWidget)
    └── widgets/                             # (optional) Feature-scoped widgets
```

---

## 5. Coding Conventions & Style

### 5.1 Naming

| Element          | Convention            | Example                           |
| ---------------- | --------------------- | --------------------------------- |
| Feature folder   | `snake_case`          | `lib/features/mini_apps/`         |
| Dart files       | `snake_case`          | `profile_api_service.dart`        |
| Classes          | `PascalCase`          | `ProfileApiService`               |
| Providers        | `camelCaseProvider`   | `profileProvider`, `authProvider` |
| Private fields   | `_camelCase`          | `_apiService`, `_repository`      |
| Constants        | `camelCase`           | `defaultPageSize`                 |
| Enums            | `PascalCase` + `camelCase` values | `AuthStatus.authenticated` |
| Section comments | `// ── Section Name ──` | `// ── Feature: Auth ──`         |

### 5.2 Class Patterns

- **Private constructors for utility classes**: `AppColors._();`, `ApiConstants._();`
- **Sealed classes** for sum types: `sealed class ApiResult<T>`, `sealed class Failure`, `sealed class AppException`
- **Const constructors** wherever possible: `const ProfileState({...})`
- **Named parameters only** for constructors (except simple positional for sealed subclasses)
- **`factory` constructors** for `fromJson` on models
- **`late final`** for injected dependencies in Notifiers

### 5.3 Import Style

- Use **`package:vc_super_app/` imports** (absolute package imports) for consistency and better IDE refactoring support
- Imports are grouped: Dart SDK → External packages → Project `package:vc_super_app/` imports
- No barrel files — import each file directly

### 5.4 Widget Conventions

- Screens extend **`ConsumerWidget`** (Riverpod-aware stateless)
- Use **`ConsumerStatefulWidget`** only when lifecycle methods are needed
- The root `App` widget is a `ConsumerWidget` using `MaterialApp.router`
- Use `AppColors` and `AppTextStyles` constants — never hardcode colors or text styles
- Use shared widgets from `core/widgets/` (e.g. `AppButton`, `AppAlertDialog`, `AppCircularProgressIndicator`)

### 5.5 State Management (Riverpod)

- **`AsyncNotifierProvider<Notifier, State>`** is the primary pattern for features with async data
- State classes are immutable, use `const` constructors and `copyWith` when needed
- Notifiers get repositories from GetIt: `_repository = getIt<FeatureRepository>()`
- Provider declarations are **top-level `final`** variables:
  ```dart
  final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
  ```

### 5.6 Dependency Injection (GetIt)

- All services and repositories are registered in `lib/core/di/injection.dart`
- Use **`registerLazySingleton`** for services and repositories
- Use **`registerSingleton`** only for things that need immediate initialization (e.g. `HiveStorageService`)
- DI registration follows the pattern:
  ```dart
  // ── Feature: FeatureName ──
  getIt.registerLazySingleton<FeatureApiService>(
    () => FeatureApiService(dio: getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<FeatureRepository>(
    () => FeatureRepositoryImpl(apiService: getIt<FeatureApiService>()),
  );
  ```

### 5.7 API Service Pattern

Every API service **extends `BaseApiService`** and uses the `request<T>()` method, which wraps Dio calls into `ApiResult<T>`:

```dart
class ProfileApiService extends BaseApiService {
  ProfileApiService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<ApiResult<List<Profile>>> getItems({required int page, int? limit}) {
    return request<List<Profile>>(
      call: _dio.get('/endpoint', queryParameters: { '_page': page, '_limit': limit }),
      mapper: (data) {
        final list = data as List<dynamic>;
        return list.map((json) => Profile.fromJson(json as Map<String, dynamic>)).toList();
      },
    );
  }
}
```

### 5.8 Repository Pattern

- **Domain layer**: abstract class defining the contract
  ```dart
  abstract class ProfileRepository {
    Future<List<Profile>> getItems({required int page, int? limit});
  }
  ```
- **Data layer**: implementation calling the API service and converting `ApiResult` to domain types
  ```dart
  class ProfileRepositoryImpl implements ProfileRepository {
    ProfileRepositoryImpl({required ProfileApiService apiService}) : _apiService = apiService;
    final ProfileApiService _apiService;

    @override
    Future<List<Profile>> getItems({required int page, int? limit}) async {
      final result = await _apiService.getItems(page: page, limit: limit);
      return result.when(
        success: (data) => data,
        failure: (message, statusCode) => throw NetworkFailure(message: message),
      );
    }
  }
  ```

### 5.9 Error Handling

| Layer          | Type Used      | Purpose                                    |
| -------------- | -------------- | ------------------------------------------ |
| Network/API    | `AppException` | Typed Dio error mapping (via `GlobalErrorHandler`) |
| Repository     | `Failure`      | Domain-level error (thrown to notifiers)    |
| Presentation   | `try/catch`    | Caught in Notifiers, set as state error    |

### 5.10 Logging

Use `AppLogger` from `core/utils/logger.dart`:
```dart
AppLogger.debug('message', tag: 'TAG');
AppLogger.info('message', tag: 'TAG');
AppLogger.warning('message', tag: 'TAG');
AppLogger.error('message', tag: 'TAG', error: e, stackTrace: stackTrace);
```

---

## 6. Routing (GoRouter)

- Routes are defined in `lib/core/router/app_router.dart`
- The router is a **Riverpod `Provider<GoRouter>`** (`routerProvider`)
- Auth state changes trigger `refreshListenable` to re-evaluate redirects
- Route guard logic:
  - Unauthenticated → redirect to `/login`
  - Authenticated on `/login` or `/splash` → redirect to `/`
  - Admin routes check `user.isAdmin`
- **Navigating**: use `context.push('/route')` or `context.go('/route')`

### Adding a new route

1. Import the screen at the top of `app_router.dart` (before the `// [GENERATED_IMPORTS_ROUTER]` marker)
2. Add a `GoRoute` entry in the `routes` list (before the `// [GENERATED_ROUTES_ROUTER]` marker)

---

## 7. Environment & Flavors

| Flavor       | Entry Point          | .env File         | App Name            |
| ------------ | -------------------- | ----------------- | ------------------- |
| `dev`        | `main_dev.dart`      | `.env.dev`        | VC SuperApp Dev     |
| `staging`    | `main_staging.dart`  | `.env.staging`    | VC SuperApp Staging |
| `production` | `main_prod.dart`     | `.env.production` | VC SuperApp         |

**Run commands:**
```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor production -t lib/main_prod.dart
```

`.env` files contain:
```
DEV_BASE_URL=https://api.dev.example.com
DEV_IMG_URL=https://img.dev.example.com
```

Access via `EnvConfig.baseUrl`, `EnvConfig.appName`, `EnvConfig.isDev`, etc.

---

## 8. Bootstrap Sequence

The app boots in this exact order (see `bootstrap.dart`):

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Load environment config (`EnvConfig.initDev/Staging/Production`)
3. `GlobalErrorHandler.init()` (Flutter error handler + Crashlytics)
4. `NotificationService().initialize()`
5. `Firebase.initializeApp()` + `FirebaseService.initialize()` + `PopupService.initialize()`
6. `configureDependencies()` (GetIt DI registration)
7. `runApp(ProviderScope(child: App()))`

---

## 9. Boilerplate Generation Tool

**Location:** `tools/generate_feature.dart`

**Usage:**
```bash
dart run tools/generate_feature.dart <feature_name>
```

This tool auto-generates a complete feature module with 6 files:

| Generated File                                        | What It Does                                   |
| ----------------------------------------------------- | ---------------------------------------------- |
| `domain/models/<name>.dart`                           | Domain model with `fromJson`                   |
| `domain/<name>_repository.dart`                       | Abstract repository interface                  |
| `data/<name>_api_service.dart`                        | API service extending `BaseApiService`          |
| `data/<name>_repository_impl.dart`                    | Repository implementation                      |
| `presentation/<name>_provider.dart`                   | Riverpod `AsyncNotifierProvider` + State class |
| `presentation/<name>_screen.dart`                     | `ConsumerWidget` scaffold UI                   |

It also **auto-injects** into:
- **DI** (`injection.dart`): adds imports and `registerLazySingleton` calls at the `// [GENERATED_IMPORTS_INJECTION]` and `// [GENERATED_DEPENDENCIES_INJECTION]` markers
- **Router** (`app_router.dart`): adds import and `GoRoute` at the `// [GENERATED_IMPORTS_ROUTER]` and `// [GENERATED_ROUTES_ROUTER]` markers

> **⚠️ IMPORTANT:** Never remove the `// [GENERATED_*]` comment markers in `injection.dart` and `app_router.dart`. They are anchors for the code generation tool.

---

## 10. Localization System

- **Supported languages**: `en`, `km`
- **Translation files**: `assets/lang/en.json`, `assets/lang/km.json` (bundled with app)
- **Runtime translations** are downloaded from the server post-login and merged with local files
- **Key resolution**: dot-notation keys (e.g. `setting.about_app`) are resolved via nested map traversal
- **Usage in widgets**:
  ```dart
  ref.watch(localizationProvider);  // Trigger rebuild on language change
  final notifier = ref.read(localizationProvider.notifier);
  Text(notifier.translate('setting.about_app'))
  ```

---

## 11. Network Layer Details

### DioClient (`data/network/dio_client.dart`)
- Creates two Dio instances: primary `_dio` and `_tokenDio` (for refresh to avoid interceptor recursion)
- Interceptor order matters: **Auth → Cache → Retry → Logger**
- Base URL comes from `EnvConfig.baseUrl`

### Interceptors
| Interceptor         | Purpose                                                       |
| -------------------- | ------------------------------------------------------------- |
| `AuthInterceptor`    | Attaches Bearer token; handles 401 with token refresh + retry |
| `CacheInterceptor`   | Caches GET responses in Hive                                  |
| `RetryInterceptor`   | Retries failed requests with exponential backoff              |
| `PrettyDioLogger`    | Debug-only request/response logging                           |

### ApiResult<T> (`sealed class`)
```dart
result.when(
  success: (data) => data,
  failure: (message, statusCode) => throw NetworkFailure(message: message),
);
```

---

## 12. Theme & Design Tokens

### Colors (`AppColors`)
- **Primary**: deep blue palette (`primary50` → `primary950`, base: `#063E89`)
- **Secondary**: lighter blue palette
- **Neutral**: grayscale (`neutral10` white → `neutral950` black)
- **Semantic**: `red`, `yellow`, `green`, `orange` palettes

### Text Styles (`AppTextStyles`)
M3 type scale: `displayLarge` → `labelSmall`. Always use these constants.

### Theme (`AppTheme`)
- Material 3 enabled (`useMaterial3: true`)
- Uses `ColorScheme.fromSeed(seedColor: AppColors.primary400)`
- Both `light` and `dark` themes defined
- Consistent card radius (12), button radius (12), input radius (12)

---

## 13. Key Dependencies

| Package                     | Purpose                         |
| --------------------------- | ------------------------------- |
| `dio`                       | HTTP client                     |
| `get_it`                    | Service locator / DI            |
| `flutter_riverpod`          | State management                |
| `go_router`                 | Declarative routing             |
| `hive_flutter`              | Local key-value cache           |
| `flutter_secure_storage`    | Encrypted credential storage    |
| `shared_preferences`        | Simple local preferences        |
| `firebase_core/messaging/...` | Firebase integration          |
| `freezed_annotation` + `freezed` | Immutable data classes (dev) |
| `json_annotation` + `json_serializable` | JSON serialization (dev) |
| `flutter_dotenv`            | .env file loading               |
| `webview_flutter`           | In-app webview for mini-apps    |
| `pretty_dio_logger`         | Debug Dio logging               |

---

## 14. Rules for AI Agents

### When creating a new feature:
1. **Use the generator tool** or follow its exact output structure manually
2. Place files under `lib/features/<snake_case_name>/`
3. Always use the three-layer structure: `data/`, `domain/`, `presentation/`
4. Register DI in `injection.dart` at the `// [GENERATED_DEPENDENCIES_INJECTION]` marker
5. Register route in `app_router.dart` at the `// [GENERATED_ROUTES_ROUTER]` marker
6. Never forget imports at the corresponding `// [GENERATED_IMPORTS_*]` markers

### When modifying existing code:
1. Keep existing patterns — don't introduce new state management or architecture patterns
2. Use `AppColors`, `AppTextStyles`, and shared widgets from `core/widgets/`
3. Use `AppLogger` for logging — never use bare `print()` in production code
4. Use `ApiResult.when()` pattern in repository implementations
5. Throw `Failure` subtypes from repositories, catch in notifiers

### Never do:
- ❌ Remove `// [GENERATED_*]` comment markers
- ❌ Use `ChangeNotifier`/`Provider` (old pattern) — use Riverpod `AsyncNotifier`
- ❌ Hardcode colors, text styles, or dimensions
- ❌ Use relative imports — prefer `package:vc_super_app/` for all project imports
- ❌ Add logic to `main.dart` — all bootstrap logic goes in `bootstrap.dart`
- ❌ Create barrel files (no `index.dart` or `exports.dart`)
- ❌ Use `context.read` for state that should react to changes — use `ref.watch`
