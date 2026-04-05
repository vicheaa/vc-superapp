# VC SuperApp

A production-grade Flutter Super App that hosts native screens alongside dynamically loaded web-based mini-apps. Built with Clean Architecture, Riverpod state management, and a robust JavaScript bridge for native ↔ web communication.

---

## Table of Contents

- [Quick Start](#-quick-start)
- [Architecture Overview](#-architecture-overview)
- [Project Structure](#-project-structure)
- [Design Patterns & Why](#-design-patterns--why)
- [State Management](#-state-management)
- [Dependency Injection](#-dependency-injection)
- [Networking Layer](#-networking-layer)
- [Authentication Flow](#-authentication-flow)
- [Mini-App System](#-mini-app-system)
- [Localization](#-localization)
- [Theming & Design Tokens](#-theming--design-tokens)
- [Feature Generator](#-feature-generator)
- [Things Every Developer Should Know](#-things-every-developer-should-know)

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK `^3.10.1`
- Dart SDK (bundled with Flutter)
- Xcode (for iOS)
- Android Studio / Android SDK (for Android)
- A copy of the `.env.*` files (ask a team member)

### 1. Clone & Install

```bash
git clone <repository-url>
cd vc-superapp
flutter pub get
```

### 2. Environment Setup

The app uses [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) for environment-specific configuration. Create the required `.env` files in the project root (they are git-ignored):

| File              | Required Variables                           |
| ----------------- | -------------------------------------------- |
| `.env.dev`        | `DEV_BASE_URL`, `DEV_IMG_URL` (optional)     |
| `.env.staging`    | `STAGING_BASE_URL`, `STAGING_IMG_URL` (optional) |
| `.env.production` | `PROD_BASE_URL`, `PROD_IMG_URL` (optional)   |

Example `.env.dev`:
```
DEV_BASE_URL=https://api.dev.example.com
DEV_IMG_URL=https://img.dev.example.com
```

> Copy from `.env.example` and fill in the values for your environment.

### 3. Firebase Setup

This project uses multiple Firebase services. Each build flavor connects to its own Firebase project (or app within a project) so that dev/staging/production telemetry and notifications stay separated.

#### 3.1 Firebase Console — Create Apps

You need **three Firebase apps** (one per flavor), each with the correct **package name / bundle ID**:

| Flavor       | Android Package Name       | iOS Bundle ID               |
| ------------ | -------------------------- | --------------------------- |
| `dev`        | `com.vc.super_app.dev`     | `com.vc.superApp.dev`       |
| `staging`    | `com.vc.super_app.staging` | `com.vc.superApp.staging`   |
| `production` | `com.vc.super_app`         | `com.vc.superApp`           |

> The Android `applicationIdSuffix` is defined in `android/app/build.gradle.kts` under `productFlavors`.

#### 3.2 Download & Place Config Files

##### Android (`google-services.json`)

Download each flavor's `google-services.json` from the Firebase Console and place it in the **flavor-specific source set**:

```
android/app/src/
├── dev/
│   └── google-services.json        ← Firebase app for com.vc.super_app.dev
├── staging/
│   └── google-services.json        ← Firebase app for com.vc.super_app.staging
└── production/
    └── google-services.json        ← Firebase app for com.vc.super_app
```

> The `build.gradle.kts` conditionally applies the Google Services plugin only if at least one `google-services.json` is found.

##### iOS (`GoogleService-Info.plist`)

For iOS, you need flavor-specific build phases or Xcode configurations:

1. Create folders for each flavor in Xcode (e.g., `ios/Runner/dev/`, `ios/Runner/staging/`, `ios/Runner/production/`)
2. Place the corresponding `GoogleService-Info.plist` in each
3. Add a **Run Script build phase** that copies the correct plist based on the active configuration

Alternatively, use the [firebase_core FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) to auto-generate per-flavor configs:
```bash
flutterfire configure --project=<your-project-id>
```

#### 3.3 Firebase Service Account (Server-Side / CI)

The `firebase-credential/` directory (git-ignored) holds service account JSONs for CI/CD or server-side operations:

```
firebase-credential/
├── firebase-service-dev.json
├── firebase-service-staging.json
└── firebase-service-prod.json
```

> Ask a team lead for these files. They are **never committed to source control**.

#### 3.4 Firebase Services Used

| Service                        | Package                       | Purpose                                           |
| ------------------------------ | ----------------------------- | ------------------------------------------------- |
| **Firebase Core**              | `firebase_core`               | Initialization                                    |
| **Firebase Auth**              | `firebase_auth`               | Anonymous auth (for FIAM device targeting)         |
| **Cloud Messaging (FCM)**      | `firebase_messaging`          | Push notifications                                |
| **In-App Messaging (FIAM)**    | `firebase_in_app_messaging`   | Server-controlled in-app popups / campaigns        |
| **App Installations (FID)**    | `firebase_app_installations`  | Device ID for targeting FIAM test messages          |
| **Analytics**                  | `firebase_analytics`          | Event tracking                                    |
| **Crashlytics**                | `firebase_crashlytics`        | Production crash reporting                        |

#### 3.5 Firebase Console — Enable Required Services

After creating the Firebase project, enable these in the Firebase Console:

1. **Authentication** → Sign-in method → Enable **Anonymous** (required for In-App Messaging device targeting)
2. **Cloud Messaging** → Enabled by default
3. **In-App Messaging** → Enabled by default (create campaigns in Console)
4. **Crashlytics** → Follow the Console onboarding wizard

#### 3.6 Initialization Order (in `bootstrap.dart`)

Firebase initializes in this specific sequence:

```
1. NotificationService().initialize()    ← Create local notification channel
2. Firebase.initializeApp()              ← Core Firebase init
3. FirebaseService.initialize()          ← FCM setup:
   ├── Anonymous sign-in (for FIAM)
   ├── Request notification permissions
   ├── Register foreground/background/terminated message handlers
   └── Print FCM token to console
4. PopupService.instance.initialize()    ← In-App Messaging setup:
   └── Print Firebase Installation ID (FID) to console
```

#### 3.7 Push Notification Flow

```
Server / Firebase Console sends push
    ↓
┌─ App in FOREGROUND ─────────────────────────┐
│  FirebaseMessaging.onMessage listener        │
│  → _handleForegroundMessage()                │
│  → NotificationService.showNotification()    │
│  → Shows local notification with image       │
└──────────────────────────────────────────────┘
┌─ App in BACKGROUND ─────────────────────────┐
│  @pragma('vm:entry-point')                   │
│  _firebaseMessagingBackgroundHandler()        │
│  → NotificationService.showNotification()    │
└──────────────────────────────────────────────┘
┌─ App TERMINATED ────────────────────────────┐
│  messaging.getInitialMessage()               │
│  → Handle deep link / navigation             │
└──────────────────────────────────────────────┘
```

#### 3.8 Testing FCM & In-App Messaging

**Getting your tokens** — When the app starts in debug mode, look for these in the console:

```
🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀
🔥 FCM_TOKEN: <your-fcm-token>
🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀

✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨
🔥 FIAM Installation ID (FID): <your-fid>
✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨
```

**Test push notification:**
1. Copy the FCM token from the console log
2. Go to Firebase Console → Cloud Messaging → **Send test message**
3. Paste the FCM token → Send

**Test in-app popup:**
1. Copy the FID (Firebase Installation ID) from the console log
2. Go to Firebase Console → In-App Messaging → Create campaign
3. Click **Test on device** → paste the FID → Test

#### 3.9 Common Troubleshooting

| Problem                              | Solution                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------ |
| `google-services.json` not found     | Ensure the file is in `android/app/src/<flavor>/`, not in `android/app/` |
| `MissingPluginException` on FIAM     | **Cold restart required** — hot reload/restart won't work after adding native plugins |
| FCM token is `null`                  | Check internet connection; ensure Google Play Services is installed on the device/emulator |
| Anonymous auth fails                 | Enable "Anonymous" in Firebase Console → Auth → Sign-in method           |
| Crashlytics not reporting            | Only active in release/production mode (`kDebugMode == false`)           |
| In-App Message not showing           | FIAM has a rate limit (1 per session). Kill and relaunch the app to test again |

### 4. Run

```bash
# Development (default)
flutter run --flavor dev -t lib/main_dev.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Production
flutter run --flavor production -t lib/main_prod.dart
```

### 5. Code Generation (Freezed / JSON Serializable)

If you modify any `@freezed` or `@JsonSerializable` annotated classes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🏗 Architecture Overview

The app follows **Feature-first Clean Architecture** — a layered approach where each feature is self-contained with its own `data`, `domain`, and `presentation` layers, while shared infrastructure lives in `core/` and `data/`.

### Why Clean Architecture?

1. **Testability** — Each layer can be tested in isolation. Repository interfaces can be mocked in presentation tests.
2. **Separation of concerns** — UI code never knows about Dio, and API services never know about widgets.
3. **Scalability** — New features are isolated modules. Adding a feature doesn't touch existing code.
4. **Replaceability** — Swapping Dio for `http`, or Riverpod for Bloc, requires changes in only one layer.

### Layer Responsibilities

```
┌──────────────────────────────────────────────────────────────────┐
│  Presentation Layer                                              │
│  Screens (ConsumerWidget), Providers (AsyncNotifier), Widgets    │
│  • Renders UI based on state                                     │
│  • Dispatches user actions to Notifiers                          │
│  • NEVER calls APIs or accesses storage directly                 │
├──────────────────────────────────────────────────────────────────┤
│  Domain Layer                                                    │
│  Abstract Repositories, Models, State classes                    │
│  • Pure Dart — no Flutter, no packages                           │
│  • Defines the contract (what, not how)                          │
│  • Models are immutable with fromJson factory constructors       │
├──────────────────────────────────────────────────────────────────┤
│  Data Layer                                                      │
│  API Services, Repository Implementations                        │
│  • Implements domain contracts                                   │
│  • Handles network calls, caching, and error mapping             │
│  • Returns ApiResult<T> from API services                        │
│  • Throws Failure subtypes from repository implementations       │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User taps button
    ↓
Screen calls ref.read(provider.notifier).doSomething()
    ↓
Notifier calls repository.fetchData()  (abstract interface)
    ↓
RepositoryImpl calls apiService.getData()  (concrete)
    ↓
ApiService extends BaseApiService → calls Dio
    ↓
Dio → AuthInterceptor (attach token) → CacheInterceptor → RetryInterceptor → Server
    ↓
Response wrapped in ApiResult<T> (success or failure)
    ↓
RepositoryImpl.result.when(success: return, failure: throw Failure)
    ↓
Notifier catches error → updates AsyncValue state
    ↓
Screen rebuilds via ref.watch(provider)
```

---

## 📁 Project Structure

```
lib/
├── main.dart                     # Default entry point (runs dev)
├── main_dev.dart                 # Dev flavor entry
├── main_staging.dart             # Staging flavor entry
├── main_prod.dart                # Production flavor entry
├── bootstrap.dart                # Shared bootstrap (env, firebase, DI, runApp)
├── app.dart                      # Root MaterialApp.router widget
│
├── core/                         # Shared infrastructure (cross-feature)
│   ├── config/env_config.dart    # Environment configuration
│   ├── constants/                # App-wide constants (API, storage keys)
│   ├── di/injection.dart         # GetIt service locator setup
│   ├── error/                    # AppException, Failure, GlobalErrorHandler
│   ├── router/app_router.dart    # GoRouter configuration
│   ├── services/                 # Firebase, Notifications, Popups
│   ├── theme/                    # AppColors, AppTextStyles, AppTheme
│   ├── utils/                    # Logger, helpers
│   └── widgets/                  # Reusable UI components (Button, Dialog, etc.)
│
├── data/                         # Shared data infrastructure
│   ├── network/                  # DioClient, BaseApiService, ApiResult, Interceptors
│   ├── local/                    # SecureStorage, HiveStorage, LocalStorage
│   └── dto/                      # Shared DTOs (PaginatedResponse)
│
├── domain/                       # Shared domain base classes
│   └── base/                     # BaseViewModel, PaginationMixin
│
└── features/                     # Feature modules
    ├── auth/                     # Authentication (login, splash, session)
    ├── home/                     # Home screen + mini-app grid
    ├── profile/                  # User profile & settings
    ├── localization/             # Multi-language support (en, km)
    ├── miniapps/                 # Mini-app registry, OTA download/install
    └── webview/                  # WebView host + JavaScript bridge

tools/
└── generate_feature.dart         # CLI feature scaffolding tool

assets/
├── lang/                         # Bundled translation JSON files
├── icon/                         # App icons per flavor
└── fonts/kantumruy/              # Custom Kantumruy Pro font
```

---

## 🧩 Design Patterns & Why

### 1. Repository Pattern
- **What:** Domain layer defines abstract repository interfaces. Data layer provides concrete implementations.
- **Why:** Decouples business logic from data sources. You can swap from REST to GraphQL, or from remote to local cache, without touching any UI or domain code.

### 2. Sealed Classes for Results & Errors
- **What:** `ApiResult<T>` is a sealed class with `ApiSuccess` and `ApiFailure` variants. `Failure` and `AppException` are also sealed hierarchies.
- **Why:** Exhaustive pattern matching with `.when()`. The compiler forces you to handle every case — no forgotten error states.

### 3. Service Locator (GetIt)
- **What:** All dependencies are registered centrally in `injection.dart` and resolved via `getIt<T>()`.
- **Why:** Keeps constructor injection clean while avoiding Riverpod-only DI (which would leak framework concerns into the domain layer).

### 4. AsyncNotifier (Riverpod)
- **What:** Presentation state is managed by `AsyncNotifierProvider` — providing `AsyncValue<State>` with built-in loading/error/data states.
- **Why:** No manual loading flags or error strings needed. The UI just calls `state.when(loading: ..., error: ..., data: ...)`.

### 5. BaseApiService + request\<T\>()
- **What:** All API services extend `BaseApiService` and call `request<T>(call: ..., mapper: ...)`.
- **Why:** Centralizes Dio error handling, logging, and response mapping. Every API call gets consistent error handling for free.

### 6. Interceptor Chain
- **What:** Dio interceptors stack: Auth → Cache → Retry → Logger.
- **Why:** Cross-cutting concerns (auth tokens, caching, retries, logging) are handled transparently. API services never worry about tokens or retries.

### 7. Feature-first Folder Structure
- **What:** Each feature is a self-contained folder with `data/`, `domain/`, `presentation/`.
- **Why:** Features are isolated. Developers work in their feature folder without conflicting with others. Easy to extract into a separate package if needed.

---

## 🔄 State Management

### Riverpod (flutter_riverpod)

This project uses **Riverpod 3.x** as the sole state management solution. Here's how it's wired:

### Provider Types in Use

| Provider Type                          | When to Use                                 | Example                         |
| -------------------------------------- | ------------------------------------------- | ------------------------------- |
| `AsyncNotifierProvider<N, State>`      | Feature state with async operations          | `authProvider`, `profileProvider` |
| `FutureProvider.autoDispose<T>`        | One-shot async data fetches                  | `miniAppsProvider`              |
| `FutureProvider<T>`                    | Async initialization (singletons)            | `localizationServiceProvider`   |
| `Provider<T>`                          | Synchronous value / static dependency        | `routerProvider`, `authRepositoryProvider` |

### Standard Feature State Pattern

Every feature with async data follows this exact pattern:

```dart
// 1. Define State
class FeatureState {
  const FeatureState({
    this.items = const [],
    this.isLoading = true,
    this.errorMessage,
  });
  final List<Feature> items;
  final bool isLoading;
  final String? errorMessage;
}

// 2. Define Provider + Notifier
final featureProvider = AsyncNotifierProvider<FeatureNotifier, FeatureState>(
  FeatureNotifier.new,
);

class FeatureNotifier extends AsyncNotifier<FeatureState> {
  late final FeatureRepository _repository;

  @override
  Future<FeatureState> build() async {
    _repository = getIt<FeatureRepository>();
    return _loadData();
  }

  Future<FeatureState> _loadData() async {
    try {
      final items = await _repository.getItems(page: 1);
      return FeatureState(items: items, isLoading: false);
    } catch (e) {
      return FeatureState(isLoading: false, errorMessage: e.toString());
    }
  }
}

// 3. Consume in UI
class FeatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureProvider);

    return state.when(
      data: (data) => /* render data.items */,
      loading: () => /* spinner */,
      error: (err, stack) => /* error UI */,
    );
  }
}
```

### Key Rules

- `ref.watch()` — for reactive UI rebuilds (inside `build()`)
- `ref.read()` — for one-shot actions (button taps, callbacks)
- `ref.listen()` — for side effects (showing snackbars, navigation)
- Never use `ref.read` where `ref.watch` should be used — it won't rebuild
- Notifiers access repositories through `getIt<Repository>()` (not through Riverpod providers)

---

## 💉 Dependency Injection

### GetIt Service Locator

All dependencies are registered in [`lib/core/di/injection.dart`](lib/core/di/injection.dart). Registration happens during bootstrap, before `runApp()`.

### Registration Order

```
1. Local Storage     → HiveStorageService, LocalStorageUtils, SecureStorageService
2. Network           → DioClient (depends on SecureStorage + HiveStorage)
3. Feature Services  → ApiService → RepositoryImpl (each feature)
```

### Pattern

```dart
// ── Feature: Profile ──
getIt.registerLazySingleton<ProfileApiService>(
  () => ProfileApiService(dio: getIt<DioClient>().dio),
);
getIt.registerLazySingleton<ProfileRepository>(
  () => ProfileRepositoryImpl(apiService: getIt<ProfileApiService>()),
);
```

### ⚠️ Code Generation Markers

The `injection.dart` and `app_router.dart` files contain special comment markers used by the [Feature Generator](#-feature-generator):

```dart
// [GENERATED_IMPORTS_INJECTION]    ← Import marker (injection.dart)
// [GENERATED_DEPENDENCIES_INJECTION] ← Registration marker (injection.dart)
// [GENERATED_IMPORTS_ROUTER]       ← Import marker (app_router.dart)
// [GENERATED_ROUTES_ROUTER]        ← Route marker (app_router.dart)
```

**Never delete these markers.** The generator appends new code right before them.

---

## 🌐 Networking Layer

### Components

| Component          | File                           | Role                                              |
| ------------------ | ------------------------------ | ------------------------------------------------- |
| `DioClient`        | `data/network/dio_client.dart` | Creates & configures Dio with all interceptors     |
| `BaseApiService`   | `data/network/base_api_service.dart` | Abstract class — wraps Dio calls into `ApiResult` |
| `ApiResult<T>`     | `data/network/api_result.dart` | Sealed class: `ApiSuccess<T>` / `ApiFailure<T>`   |
| `AuthInterceptor`  | `interceptors/auth_interceptor.dart` | Attach Bearer token + 401 auto-refresh           |
| `CacheInterceptor` | `interceptors/cache_interceptor.dart` | Cache GET responses in Hive                      |
| `RetryInterceptor` | `interceptors/retry_interceptor.dart` | Exponential backoff retry (max 3 attempts)       |

### Interceptor Order (matters!)

```
Request → Auth (add token) → Cache (check local) → Retry → Logger → Server
Response ← Logger ← Retry ← Cache (save) ← Auth (handle 401) ← Server
```

### Token Refresh Flow

When any request returns **401**:
1. `AuthInterceptor` intercepts the error
2. Reads the refresh token from `SecureStorage`
3. Uses a **separate Dio instance** (`_tokenDio`) to call `/auth/refresh` — avoids interceptor recursion
4. Saves new access + refresh tokens
5. Replays the original request with the new token
6. If refresh fails → clears all tokens → triggers logout

---

## 🔐 Authentication Flow

```
App Launch
    ↓
bootstrap() → configureDependencies() → runApp()
    ↓
GoRouter initialLocation: '/splash'
    ↓
AuthController.build() → AuthRepository.init()
    ↓
Check SecureStorage for existing access token + user data
    ↓
┌─ Token found → AuthStatus.authenticated → redirect to '/' (Home)
└─ No token   → AuthStatus.unauthenticated → redirect to '/login'
    ↓
User logs in → AuthRepository.login() → API call
    ↓
Save tokens + user data to SecureStorage
    ↓
Emit AuthState(authenticated, user) via stream
    ↓
AuthController listens → updates AsyncValue → GoRouter refreshes → redirect to '/'
    ↓
On login success → download/sync translations in background
```

### RBAC (Role-Based Access Control)

The `User` model includes `role` (admin, manager, user) and `permissions` list. Route guards in `app_router.dart` check `user.isAdmin` for admin-only routes.

---

## 📱 Mini-App System

The Super App hosts web-based mini-apps inside a native WebView. This is the core "super app" capability.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Shell                         │
│                                                          │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │ Home Grid │───▶│ MiniApp Repo │───▶│ OTA Download  │  │
│  │ (UI)      │    │ (Registry)   │    │ & Install     │  │
│  └──────────┘    └──────────────┘    └───────┬───────┘  │
│        │                                      │          │
│        ▼                                      ▼          │
│  ┌────────────────────────────────────────────────────┐  │
│  │              SuperAppWebView                       │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │            WebViewWidget                     │  │  │
│  │  │                                              │  │  │
│  │  │  ┌────────────────────────────────────────┐  │  │  │
│  │  │  │      React / Vue / Vanilla JS App     │  │  │  │
│  │  │  │   (runs inside WebView as web app)    │  │  │  │
│  │  │  └────────────────┬───────────────────────┘  │  │  │
│  │  │                   │                          │  │  │
│  │  │         ┌─────────┴─────────┐                │  │  │
│  │  │         │ SuperAppBridge    │                │  │  │
│  │  │         │ (JS Channel)     │                │  │  │
│  │  │         └───────────────────┘                │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Mini-App Lifecycle

#### 1. Registry & Discovery

The backend API (`/v1/miniapps`) returns a manifest of available mini-apps:

```json
{
  "data": {
    "miniApps": [
      {
        "id": "shop",
        "name": "Shop",
        "version": "1.2.0",
        "description": "E-commerce mini-app",
        "downloadUrl": "https://cdn.example.com/miniapps/shop-v1.2.0.zip",
        "iconUrl": "https://cdn.example.com/icons/shop.png",
        "bundleHash": "abc123"
      }
    ]
  }
}
```

#### 2. OTA Download & Installation

When a user taps a mini-app card on the home screen:

```
Tap mini-app card
    ↓
Check if already installed (version.txt matches manifest version)
    ↓
┌─ Installed → load from local path
└─ Not installed / outdated →
        Show download dialog
            ↓
        Download .zip from downloadUrl (with retry up to 3x)
            ↓
        Extract .zip to Documents/miniapps/<app_id>/
            ↓  (runs in background Isolate for performance)
        Write version.txt marker
            ↓
        Find index.html (recursive search)
            ↓
        Launch via SuperAppWebView
```

Key details:
- Downloads run on a **clean Dio instance** (separate from the app's interceptor-equipped Dio) with extended timeouts
- Extraction runs in a **background Isolate** to keep the UI responsive
- Version checking prevents re-downloading unchanged bundles

#### 3. Serving Mini-Apps Locally

There are two loading modes:

| Mode            | When Used                          | How                                              |
| --------------- | ---------------------------------- | ------------------------------------------------ |
| **Asset-based** | Mini-app bundled in Flutter assets | `loadFlutterAsset('assets/mini_apps/<id>/index.html')` |
| **OTA (local server)** | Downloaded from server        | Spin up `HttpServer` on `127.0.0.1:<random port>`, serve files from the extracted directory, load via `http://127.0.0.1:<port>/` |

> **Why a local HTTP server for OTA?**  Android WebView blocks `file://` cross-origin requests (CORS). Serving via `http://localhost` avoids all CORS issues for JS/CSS asset loading.

### JavaScript Bridge Communication

The bridge enables **bidirectional communication** between Flutter and the web app running inside the WebView.

#### Flutter → Web (Injecting data into the web app)

Flutter calls `runJavaScript()` to invoke global functions on the web app's `window` object:

```dart
// In SuperAppWebView
void _sendDataBackToWeb(String action, dynamic data) {
  final encodedData = jsonEncode(data);
  final jsCode = "window.receiveMessageFromNative('$action', $encodedData);";
  _controller.runJavaScript(jsCode);
}
```

The web app must define `window.receiveMessageFromNative`:

```javascript
// In React / Vanilla JS mini-app
window.receiveMessageFromNative = (action, data) => {
  switch (action) {
    case 'updateToken':
      store.setAuthToken(data);
      break;
    case 'addToCart':
      store.addProduct(data);
      break;
    case 'userInfoResponse':
      handleUserInfo(data);
      break;
  }
};
```

#### Web → Flutter (Sending events to native)

The web app sends JSON messages through the `SuperAppBridge` JavaScript channel:

```javascript
// In React / Vanilla JS mini-app
const message = JSON.stringify({
  action: 'checkoutClicked',
  data: { total: 49.99 }
});
window.SuperAppBridge.postMessage(message);
```

Flutter receives and handles these in `_handleBridgeMessage`:

```dart
void _handleBridgeMessage(JavaScriptMessage message) {
  final data = jsonDecode(message.message);
  final action = data['action'];
  final payload = data['data'] ?? {};

  switch (action) {
    case 'reactAppReady':    // Web app loaded, inject pending data
    case 'getUserInfo':      // Web app requesting user data
    case 'showDialog':       // Web app requesting native dialog
    case 'checkoutClicked':  // Web app triggering native checkout
    case 'close':            // Web app requesting to close/pop
  }
}
```

#### Supported Bridge Actions

| Direction     | Action           | Purpose                                         |
| ------------- | ---------------- | ------------------------------------------------ |
| Web → Flutter | `reactAppReady`  | Signal that the web app has loaded, triggers deferred data injection |
| Web → Flutter | `getUserInfo`    | Request native user info (token, profile)        |
| Web → Flutter | `showDialog`     | Display native dialog with custom title/message  |
| Web → Flutter | `checkoutClicked`| Trigger native payment/checkout flow             |
| Web → Flutter | `close`          | Pop the WebView and return to native navigation  |
| Flutter → Web | `updateToken`    | Inject/refresh the auth token                    |
| Flutter → Web | `addToCart`      | Push a product object into the web app's cart     |
| Flutter → Web | `userInfoResponse` | Return user data in response to `getUserInfo`  |

#### Auth Token Injection

The auth token is automatically injected into the web app on both `onPageStarted` and `onPageFinished`:

```dart
void _injectAuthToken() {
  _controller.runJavaScript("""
    window.superAppAuthToken = '${widget.authToken}';
    if (typeof window.receiveMessageFromNative === 'function') {
      window.receiveMessageFromNative('updateToken', '${widget.authToken}');
    }
  """);
}
```

This ensures the web app always has a valid token, even if it loads slowly.

### How to Add a New Mini-App

#### 1. Create the Web App

```bash
cd mini_apps
npm create vite@latest my_app -- --template react-ts
cd my_app && npm install
npm install -D vite-plugin-singlefile
```

#### 2. Configure Vite for Single-File Output

```javascript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { viteSingleFile } from "vite-plugin-singlefile"

export default defineConfig({
  plugins: [react(), viteSingleFile()],
  build: {
    outDir: '../../assets/mini_apps/my_app',
    emptyOutDir: true,
  },
  base: './'
})
```

#### 3. Implement the Bridge in Your Web App

```javascript
// src/bridge.js — required in every mini-app
window.receiveMessageFromNative = (action, data) => {
  // Handle messages from Flutter
  const event = new CustomEvent('nativeMessage', { detail: { action, data } });
  window.dispatchEvent(event);
};

export function sendToNative(action, data = {}) {
  const message = JSON.stringify({ action, data });
  if (window.SuperAppBridge) {
    window.SuperAppBridge.postMessage(message);
  }
}

// Signal to Flutter that the app is ready
export function notifyReady() {
  sendToNative('reactAppReady', {});
}
```

#### 4. Build & Register

```bash
npm run build  # Outputs to assets/mini_apps/my_app/index.html
```

Add to `pubspec.yaml`:
```yaml
assets:
  - assets/mini_apps/my_app/
```

#### 5. Navigate

```dart
context.push('/webview', extra: 'my_app');
```

---

## 🌍 Localization

### Overview

The app supports **English (`en`)** and **Khmer (`km`)** with a hybrid local-first + server-sync strategy.

### How It Works

```
App starts → Load bundled assets/lang/en.json (or km.json)
    ↓
Save to local documents directory (if newer version)
    ↓
User logs in → Download latest translations from server
    ↓
Deep-merge server data over local data → Save merged result
    ↓
UI reactively updates via localizationProvider
```

### Using Translations in UI

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // 1. Watch for reactive rebuilds on language change
  ref.watch(localizationProvider);
  final notifier = ref.read(localizationProvider.notifier);

  // 2. Translate keys (dot-notation supported)
  return Text(notifier.translate('setting.about_app'));
}
```

### Translation File Format

```json
{
  "version": "1.0.0",
  "setting": {
    "about_app": "About App",
    "privacy_policy": "Privacy Policy"
  },
  "home": {
    "welcome": "Welcome"
  }
}
```

Keys use dot-notation for nested access: `setting.about_app` → `"About App"`

---

## 🎨 Theming & Design Tokens

### Colors (`AppColors`)

The project has a curated palette — always use these constants, never hardcode hex values:

- **Primary:** Deep blue (`#063E89` base) — `AppColors.primary50` through `primary950`
- **Secondary:** Lighter blue — `AppColors.secondary50` through `secondary950`
- **Neutral:** Grayscale — `AppColors.neutral10` (white) through `neutral950` (black)
- **Semantic:** `red`, `yellow`, `green`, `orange` — for status indicators, alerts, etc.

### Text Styles (`AppTextStyles`)

Material 3 type scale constants: `displayLarge`, `headlineMedium`, `bodyLarge`, `labelSmall`, etc.

```dart
Text('Hello', style: AppTextStyles.headlineSmall.copyWith(
  color: AppColors.primary500,
  fontWeight: FontWeight.bold,
));
```

### Theme (`AppTheme`)

- Material 3 enabled
- Color scheme seeded from `AppColors.primary400`
- Both light and dark themes defined
- Consistent border radii (12px for cards, inputs, buttons)
- Custom Kantumruy Pro font bundled in assets

---

## ⚡ Feature Generator

Quickly scaffold a complete feature with all Clean Architecture layers:

```bash
dart run tools/generate_feature.dart <feature_name>
```

Example:
```bash
dart run tools/generate_feature.dart payment
```

This generates **6 files** + auto-injects DI + route:

```
lib/features/payment/
├── data/
│   ├── payment_api_service.dart      # API service (extends BaseApiService)
│   └── payment_repository_impl.dart  # Repository implementation
├── domain/
│   ├── payment_repository.dart       # Abstract repository interface
│   └── models/
│       └── payment.dart              # Domain model with fromJson
└── presentation/
    ├── payment_provider.dart          # Riverpod AsyncNotifier + State
    └── payment_screen.dart            # ConsumerWidget screen
```

It also automatically:
- Adds imports and `registerLazySingleton` calls to `injection.dart`
- Adds the screen import and `GoRoute` to `app_router.dart`

---

## 📌 Things Every Developer Should Know

### Bootstrap Sequence

The app initializes in this exact order (see `bootstrap.dart`):

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Load environment config for the current flavor
3. `GlobalErrorHandler.init()` (Flutter error handler + Crashlytics)
4. `NotificationService().initialize()`
5. Firebase initialization (Core + FCM + In-App Messaging + Popups)
6. `configureDependencies()` — GetIt DI registrations
7. `runApp(ProviderScope(child: App()))`

### Error Handling Strategy

There are **two error hierarchies** used at different layers:

| Type            | Layer           | Example                              |
| --------------- | --------------- | ------------------------------------ |
| `AppException`  | Network / Data  | `NoInternetException`, `TimeoutException`, `UnauthorizedException` |
| `Failure`       | Domain / Repo   | `NetworkFailure`, `AuthFailure`, `CacheFailure` |

- `BaseApiService` catches `DioException` → maps to `AppException` via `GlobalErrorHandler`
- Repository implementations catch `ApiResult.failure` → throw `Failure` subtypes
- Notifiers catch `Failure` → update state with error message
- `GlobalErrorHandler` reports to Firebase Crashlytics in production

### Import Conventions

Use **`package:vc_super_app/` imports** (absolute package imports) for consistency and IDE support:

```dart
// ✅ Preferred
import 'package:vc_super_app/core/theme/app_colors.dart';
import 'package:vc_super_app/features/auth/presentation/controllers/auth_controller.dart';
```

### Logging

Use `AppLogger` — never bare `print()`:

```dart
AppLogger.debug('message', tag: 'TAG');     // Debug-only
AppLogger.info('message', tag: 'TAG');      // General information
AppLogger.warning('message', tag: 'TAG');   // ⚠️ Warnings
AppLogger.error('message', tag: 'TAG', error: e, stackTrace: st);  // ❌ Errors
```

### Storage Types

| Service                | Backed By              | Use For                                  |
| ---------------------- | ---------------------- | ---------------------------------------- |
| `SecureStorageService` | FlutterSecureStorage   | Auth tokens, credentials, sensitive data |
| `HiveStorageService`   | Hive                   | API response caching                     |
| `LocalStorageUtils`    | SharedPreferences      | User preferences, language, flags        |

### Widget Conventions

- All screens are **`ConsumerWidget`** (not `StatelessWidget`)
- Use `ConsumerStatefulWidget` **only** when you need lifecycle methods
- Use shared widgets from `core/widgets/` — `AppButton`, `AppAlertDialog`, `showAppDialog`, `AppCircularProgressIndicator`
- Always use `AppColors` and `AppTextStyles` — never hardcode values

### Gotchas

- 🔴 **Never remove `// [GENERATED_*]` comment markers** — they're anchors for code generation
- 🔴 **Interceptor order matters** in `DioClient` — Auth must come before Cache and Retry
- 🔴 **Token refresh uses a separate Dio instance** (`_tokenDio`) — adding interceptors to it will cause recursion
- 🟡 **Mini-app OTA bundles must contain `index.html`** — the repository recursively searches for it
- 🟡 **OTA downloads use a clean Dio** without interceptors — don't add auth headers via the interceptor chain for CDN downloads
- 🟢 **GoRouter redirect logic is auth-driven** — it watches `authProvider` and auto-redirects on login/logout

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
