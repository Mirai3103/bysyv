# External Integrations

**Analysis Date:** 2026-05-16

## APIs & External Services

**Pixiv Public App API:**
- Pixiv app API - artwork, manga, novels, comments, users, follows, bookmarks, search, trending tags, spotlight articles, AI/restricted-mode settings, and paginated next-page fetches.
  - SDK/Client: `dio` via `PixivApiService` in `lib/data/services/pixiv_api_service.dart`.
  - Base URL: `https://app-api.pixiv.net` from `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`, and `lib/core/config/app_config.dart`.
  - Auth: bearer token loaded from `AuthSessionStore` in `lib/data/repositories/auth_session_store.dart` and attached by `PixivApiInterceptor` in `lib/data/services/pixiv_api_interceptor.dart`.
  - Client headers: Pixiv Android-compatible headers and hashed client-time header generated in `lib/data/services/pixiv_api_interceptor.dart`.

**Pixiv OAuth:**
- Pixiv OAuth token service - authorization-code exchange, password login, and refresh-token exchange.
  - SDK/Client: `dio` in `PixivAuthService` at `lib/data/services/pixiv_auth_service.dart`.
  - Base URL: `https://oauth.secure.pixiv.net`.
  - Auth: Pixiv OAuth client constants embedded in `lib/data/services/pixiv_auth_service.dart`; do not duplicate constant values into docs or logs.
  - PKCE: code verifier/challenge generation uses `crypto` in `lib/data/services/pixiv_auth_service.dart`.

**Pixiv Web Login:**
- Pixiv web auth pages - login/register WebView pages and callback interception.
  - SDK/Client: `webview_flutter` in `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`.
  - Base URL: `https://app-api.pixiv.net/web/v1/login` and `https://app-api.pixiv.net/web/v1/provisional-accounts/create` constructed in `lib/data/services/pixiv_auth_service.dart`.
  - Callback handling: `pixiv:` scheme URLs are intercepted in `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`, then exchanged through `AuthController` in `lib/ui/features/auth/view_models/auth_controller.dart`.

**Pixiv Account API:**
- Pixiv account service - provisional account creation and account edit.
  - SDK/Client: `dio` in `PixivAccountService` at `lib/data/services/pixiv_account_service.dart`.
  - Base URL: `https://accounts.pixiv.net`.
  - Auth: provisional account creation uses an embedded guest token constant in `lib/data/services/pixiv_account_service.dart`; account edits use the stored Pixiv bearer token from `AuthSessionStore`.

**Remote Images:**
- Pixiv artwork image hosts and external placeholder images - rendered through network image widgets.
  - SDK/Client: `cached_network_image` in `lib/ui/core/widgets/artwork_card.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`, and `lib/ui/features/search/views/search_screen.dart`.
  - Auth/headers: `ArtworkCard.imageHeaders` sends a Pixiv referer header from `lib/ui/core/widgets/artwork_card.dart`.
  - Placeholder URL source: `https://placewaifu.com/image/...` generated in `lib/ui/features/auth/views/auth_screen.dart`.

**GitHub Releases:**
- GitHub Actions and GitHub Release - production APK artifact build and tagged release publishing.
  - SDK/Client: workflow actions `actions/checkout@v4`, `actions/setup-java@v4`, `subosito/flutter-action@v2`, `actions/upload-artifact@v4`, and `softprops/action-gh-release@v2` in `.github/workflows/build-prod.yml`.
  - Auth: GitHub Actions repository secrets and default release token context managed by GitHub Actions.

## Data Storage

**Databases:**
- No application database integration detected in source code.
- `sqflite` native plugins appear transitively through `.flutter-plugins-dependencies`, likely from image/cache dependencies; no direct `sqflite` import or app database repository detected in `lib/`.

**File Storage:**
- Flutter secure storage - Pixiv auth session JSON persisted under key `pixiv_auth_session` in `lib/data/repositories/auth_session_store.dart`.
- Shared preferences - recent search words persisted under key `search_recent_words_v1` in `lib/data/repositories/search_recent_store.dart`.
- Cached network image storage - image/cache persistence managed by `cached_network_image` and transitive `flutter_cache_manager`; app usage is in `lib/ui/core/widgets/artwork_card.dart` and feature screens under `lib/ui/features/`.

**Caching:**
- `cached_network_image` for artwork/remote image cache in `lib/ui/core/widgets/artwork_card.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`, and `lib/ui/features/search/views/search_screen.dart`.
- No Redis, Memcached, server-side cache, or explicit custom HTTP cache detected.

## Authentication & Identity

**Auth Provider:**
- Pixiv OAuth/custom mobile-client auth.
  - Implementation: `PixivAuthService` builds Pixiv web login/register URLs, performs OAuth token exchange and refresh requests, and maps token responses to `AuthSession` in `lib/data/services/pixiv_auth_service.dart`.
  - UI flow: `AuthScreen` in `lib/ui/features/auth/views/auth_screen.dart` launches `/auth/web`; `PixivAuthWebViewScreen` in `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart` intercepts callback codes.
  - State: `AuthController` in `lib/ui/features/auth/view_models/auth_controller.dart` manages login state and persists sessions through `AuthSessionStore`.
  - Session storage: `FlutterSecureStorage` provider and `AuthSessionStore` in `lib/data/repositories/auth_session_store.dart`.
  - Route protection: `routerProvider` redirects authenticated/unauthenticated users in `lib/app/router.dart`.

## Monitoring & Observability

**Error Tracking:**
- None detected; no Sentry, Firebase Crashlytics, Datadog, Bugsnag, or equivalent dependency in `pubspec.yaml`.

**Logs:**
- No structured logging framework detected.
- Error paths are mostly surfaced as exceptions/messages from services and view models, including `PixivAuthException` in `lib/data/services/pixiv_auth_service.dart` and `PixivAccountException` in `lib/data/services/pixiv_account_service.dart`.

## CI/CD & Deployment

**Hosting:**
- GitHub Releases for Android APK artifacts via `.github/workflows/build-prod.yml`.
- No App Store, Play Store, Firebase App Distribution, web hosting, or backend hosting configuration detected.

**CI Pipeline:**
- GitHub Actions workflow `.github/workflows/build-prod.yml` triggers on tags matching `release-*`.
- Pipeline steps: checkout, Java 17 setup, Flutter 3.41.9 setup, keystore decode, `flutter pub get`, `flutter build apk --flavor prod -t lib/main_prod.dart --release`, artifact upload, GitHub Release creation.
- No test/analyze CI job detected in `.github/workflows/`.

## Environment Configuration

**Required env vars:**
- Runtime app API base URL is not environment-variable driven; it is configured in `AppConfig` from `lib/main_dev.dart`, `lib/main_staging.dart`, and `lib/main_prod.dart`.
- Android release signing requires `STORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` in `android/app/build.gradle.kts`.
- GitHub Actions release build requires repository secrets `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, and `STORE_PASSWORD` in `.github/workflows/build-prod.yml`.

**Secrets location:**
- GitHub Actions repository secrets are referenced by `.github/workflows/build-prod.yml`.
- Release signing keystore is decoded to `android/app/bysyv.keystore` during CI by `.github/workflows/build-prod.yml`.
- Pixiv OAuth/client constants are embedded in source files `lib/data/services/pixiv_auth_service.dart` and `lib/data/services/pixiv_account_service.dart`; do not copy their values into generated docs, logs, or issue text.
- Secret-like file `github_secret.txt` exists at the repository root and was not read.
- `.env` files are not detected.

## Webhooks & Callbacks

**Incoming:**
- No backend webhook endpoints detected.
- Client-side Pixiv OAuth callback handling intercepts `pixiv:` scheme navigation inside `WebView` in `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`.
- No Android intent filter or iOS URL scheme registration for `pixiv:` callback detected in `android/app/src/main/AndroidManifest.xml` or `ios/Runner/Info.plist`; the detected callback path is WebView navigation interception.

**Outgoing:**
- HTTP requests to Pixiv app API endpoints from `lib/data/services/pixiv_api_service.dart`.
- HTTP requests to Pixiv OAuth endpoint `/auth/token` from `lib/data/services/pixiv_auth_service.dart`.
- HTTP requests to Pixiv account endpoints from `lib/data/services/pixiv_account_service.dart`.
- Remote image requests through `cached_network_image` in `lib/ui/core/widgets/artwork_card.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`, and `lib/ui/features/search/views/search_screen.dart`.
- GitHub release upload actions run from `.github/workflows/build-prod.yml`.

---

*Integration audit: 2026-05-16*
