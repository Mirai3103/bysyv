<!-- refreshed: 2026-05-16 -->
# Architecture

**Analysis Date:** 2026-05-16

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                 Flutter App Composition Layer                │
│ `lib/main*.dart` -> `lib/app/app.dart` -> `lib/app/router.dart` │
├──────────────────┬──────────────────┬───────────────────────┤
│ Auth UI          │ Main Tab Shell   │ Detail/Feature UI      │
│ `lib/ui/features/auth` │ `lib/ui/core/widgets/app_tab_shell.dart` │ `lib/ui/features/*` │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                 Riverpod ChangeNotifier ViewModels           │
│ `lib/ui/features/*/view_models/*_view_model.dart`            │
│ `lib/ui/features/auth/view_models/auth_controller.dart`      │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                     Repository Layer                         │
│ `lib/data/repositories/*_repository.dart`                    │
│ `lib/data/repositories/*_store.dart`                         │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Services, DTOs, Storage, API                 │
│ `lib/data/services/*_service.dart`                           │
│ `lib/data/models/*` and `lib/domain/models/*`                │
│ Pixiv API / OAuth / SecureStorage / SharedPreferences        │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry points | Bootstrap Flutter, wrap `BysivApp` in `ProviderScope`, and select flavor config for dev/staging/prod builds. | `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart` |
| App shell | Apply `MixScope`, app `ThemeData`, and `MaterialApp.router`. | `lib/app/app.dart` |
| Router | Define auth redirects, top-level detail routes, and the indexed tab shell. | `lib/app/router.dart` |
| Tab shell | Keep `/home`, `/search`, `/news`, `/notifications`, and `/profile` in a persistent bottom-navigation shell. | `lib/ui/core/widgets/app_tab_shell.dart` |
| Feature views | Render screens, bind UI gestures to view model commands, and navigate with `go_router`. | `lib/ui/features/home/views/home_screen.dart`, `lib/ui/features/search/views/search_screen.dart`, `lib/ui/features/auth/views/auth_screen.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart` |
| View models | Own feature UI state, async loading, command methods, optimistic updates, and `notifyListeners()`. | `lib/ui/features/home/view_models/home_view_model.dart`, `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`, `lib/ui/features/auth/view_models/auth_controller.dart` |
| Repositories | Convert service/DTO results into domain models and expose feature-oriented methods. | `lib/data/repositories/artwork_repository.dart`, `lib/data/repositories/search_repository.dart`, `lib/data/repositories/user_repository.dart`, `lib/data/repositories/novel_repository.dart`, `lib/data/repositories/discover_repository.dart` |
| Services | Encapsulate HTTP clients, Pixiv OAuth, account calls, request headers, and token refresh behavior. | `lib/data/services/pixiv_api_service.dart`, `lib/data/services/pixiv_auth_service.dart`, `lib/data/services/pixiv_account_service.dart`, `lib/data/services/pixiv_api_interceptor.dart` |
| Domain models | Provide immutable app-facing data shapes used by UI and view models. | `lib/domain/models/artwork.dart`, `lib/domain/models/artwork_detail.dart`, `lib/domain/models/feed_page.dart`, `lib/domain/models/auth_session.dart` |
| API models | Parse Pixiv JSON payloads before repository mapping. | `lib/data/models/pixiv_common_models.dart`, `lib/data/models/pixiv_account_models.dart`, `lib/data/models/pixiv_recommend_response.dart` |
| Theme/design primitives | Centralize palette, Material theme, Mix tokens, shared glass panels, buttons, fields, backgrounds, and artwork cards. | `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart`, `lib/core/theme/app_mix_theme.dart`, `lib/ui/core/widgets/*` |

## Pattern Overview

**Overall:** Flutter MVVM with Riverpod provider-based dependency injection, a repository/service data layer, and feature-grouped UI.

**Key Characteristics:**
- Use `ProviderScope` at the app root and Riverpod providers for all injectable services, repositories, router, and view models (`lib/main.dart`, `lib/app/router.dart`, `lib/data/repositories/artwork_repository.dart`).
- Use `ChangeNotifierProvider` for UI state controllers that expose immutable state objects and explicit command methods (`lib/ui/features/search/view_models/search_view_model.dart`).
- Use repositories as the only bridge from view models to Pixiv API services, local secure storage, or shared preferences (`lib/data/repositories/search_repository.dart`, `lib/data/repositories/auth_session_store.dart`).
- Keep API DTOs under `lib/data/models/` and app-facing models under `lib/domain/models/`; map between them in `lib/data/repositories/pixiv_domain_mappers.dart`.
- Use `go_router` with `StatefulShellRoute.indexedStack` for tab navigation and plain top-level `GoRoute`s for auth and detail screens (`lib/app/router.dart`).

## Layers

**Bootstrap Layer:**
- Purpose: Initialize Flutter, platform system UI, app flavor config, and Riverpod scope.
- Location: `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`
- Contains: `main()` functions and `AppConfig.init(...)` calls for flavor entry points.
- Depends on: Flutter bindings, `hooks_riverpod`, `lib/app/app.dart`, and `lib/core/config/app_config.dart`.
- Used by: Flutter runtime and Makefile targets such as `make run-dev` in `Makefile`.

**Application Shell Layer:**
- Purpose: Configure the app-wide widget shell, theme, Mix tokens, and router.
- Location: `lib/app/app.dart`, `lib/app/router.dart`
- Contains: `BysivApp`, `routerProvider`, route tree, auth redirects, and `AppRoute`.
- Depends on: `go_router`, `hooks_riverpod`, theme files, shared shell widgets, and feature screens.
- Used by: All entry points and widget tests that pump `BysivApp` (`test/widget_test.dart`).

**UI Layer:**
- Purpose: Render screens and reusable widgets from state supplied by view models.
- Location: `lib/ui/features/`, `lib/ui/core/widgets/`
- Contains: Feature screens, bottom tab shell, app background, glass panel, button, text field, and artwork card primitives.
- Depends on: Feature view models, domain models, `AppColors`, `AppTheme`, `go_router`, `flutter_animate`, `lucide_icons_flutter`, and `cached_network_image`.
- Used by: Router pages and tests.

**ViewModel Layer:**
- Purpose: Own feature state, user intents, loading/error flags, pagination, debouncing, and optimistic UI updates.
- Location: `lib/ui/features/*/view_models/`
- Contains: `AuthController`, `HomeViewModel`, `SearchViewModel`, `ArtworkDetailViewModel`, and state classes such as `HomeState`, `SearchState`, `ArtworkDetailState`.
- Depends on: Repositories/stores and domain models.
- Used by: Feature views through Riverpod `ref.watch(...)`.

**Repository Layer:**
- Purpose: Present feature-oriented data operations and map service DTOs into domain models.
- Location: `lib/data/repositories/`
- Contains: Repository providers, repository classes, local stores, and `pixiv_domain_mappers.dart`.
- Depends on: Services, API models, domain models, `flutter_secure_storage`, and `shared_preferences`.
- Used by: View models and tests via provider overrides.

**Service Layer:**
- Purpose: Execute Pixiv HTTP requests, OAuth token exchange/refresh, account API operations, and Dio interceptor behavior.
- Location: `lib/data/services/`, `lib/core/network/dio_provider.dart`
- Contains: `PixivApiService`, `PixivAuthService`, `PixivAccountService`, `PixivApiInterceptor`, and `dioProvider`.
- Depends on: `dio`, `crypto`, `AppConfig`, `AuthSessionStore`, and API DTOs.
- Used by: Repositories.

**Domain Layer:**
- Purpose: Provide app-facing model types independent of widget state.
- Location: `lib/domain/models/`
- Contains: `Artwork`, `ArtworkDetail`, `AuthSession`, `FeedPage<T>`, `Novel`, `PixivCreator`, `PixivTag`, `SearchUserResult`, and related value types.
- Depends on: Mostly plain Dart; `Artwork` currently depends on Flutter `Color`.
- Used by: Repositories, view models, views, and tests.

## Data Flow

### Auth Request Path

1. App starts inside `ProviderScope` (`lib/main.dart:18`).
2. `BysivApp` watches `routerProvider` and installs `MaterialApp.router` (`lib/app/app.dart:13`, `lib/app/app.dart:21`).
3. `routerProvider` reads `authControllerProvider` and attaches it as `refreshListenable` (`lib/app/router.dart:14`, `lib/app/router.dart:19`).
4. `AuthController` loads saved tokens from `AuthSessionStore` during provider creation (`lib/ui/features/auth/view_models/auth_controller.dart:8`, `lib/ui/features/auth/view_models/auth_controller.dart:13`).
5. Router redirects authenticated users from `/auth` or `/` to `/home`, and unauthenticated users back to `/auth` (`lib/app/router.dart:20`, `lib/app/router.dart:29`).
6. Web login begins in `AuthScreen`, opens `/auth/web`, then `PixivAuthWebViewScreen` exchanges an authorization code through `AuthController` and `PixivAuthService` (`lib/app/router.dart:45`, `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`, `lib/data/services/pixiv_auth_service.dart:79`).

### Home Feed Path

1. `/home` resolves to `HomeScreen` inside the indexed tab shell (`lib/app/router.dart:86`, `lib/app/router.dart:93`).
2. `homeViewModelProvider` creates `HomeViewModel`, injects `DiscoverRepository`, and calls `loadRecommended()` (`lib/ui/features/home/view_models/home_view_model.dart:7`, `lib/ui/features/home/view_models/home_view_model.dart:11`).
3. `HomeViewModel` chooses repository methods based on `HomeFilter` (`lib/ui/features/home/view_models/home_view_model.dart:92`).
4. `DiscoverRepository` calls `PixivApiService` and maps `PixivIllust` DTOs to `Artwork` (`lib/data/repositories/discover_repository.dart:20`, `lib/data/repositories/discover_repository.dart:44`).
5. `PixivApiService` performs Dio requests and parses DTO pages (`lib/data/services/pixiv_api_service.dart:37`, `lib/data/services/pixiv_api_service.dart:637`).
6. `HomeScreen` renders loading, error, empty, and artwork grid states from `HomeState` (`lib/ui/features/home/views/home_screen.dart`).

### Search Path

1. `/search` resolves to `SearchScreen` in the second shell branch (`lib/app/router.dart:104`).
2. `searchViewModelProvider` creates `SearchViewModel`, injects `SearchRepository` and `SearchRecentStore`, then calls `initialize()` (`lib/ui/features/search/view_models/search_view_model.dart:14`, `lib/ui/features/search/view_models/search_view_model.dart:19`).
3. `SearchViewModel.initialize()` loads recent words from `SharedPreferences` and trending tags from Pixiv (`lib/ui/features/search/view_models/search_view_model.dart:40`, `lib/data/repositories/search_recent_store.dart:12`).
4. `queryChanged()` debounces autocomplete requests with a `Timer` and request counter (`lib/ui/features/search/view_models/search_view_model.dart:70`, `lib/ui/features/search/view_models/search_view_model.dart:326`).
5. `submitSearch()`, `setActiveTab()`, `setSort()`, `applyFilters()`, and `loadMore()` call `SearchRepository` for paged artwork, novel, and user result pages (`lib/ui/features/search/view_models/search_view_model.dart:90`, `lib/data/repositories/search_repository.dart:23`).

### Artwork Detail Path

1. `/artworks/:illustId` resolves to `ArtworkDetailScreen` with the path parameter (`lib/app/router.dart:55`, `lib/app/router.dart:60`).
2. `artworkDetailViewModelProvider` is `autoDispose.family` keyed by `illustId` and injects `ArtworkRepository` plus `UserRepository` (`lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart:10`).
3. `ArtworkDetailViewModel.load()` calls `ArtworkRepository.detailFull()` (`lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart:38`, `lib/data/repositories/artwork_repository.dart:54`).
4. `ArtworkRepository.detailFull()` fetches details, comments, and related artwork before mapping to `ArtworkDetail` (`lib/data/repositories/artwork_repository.dart:55`, `lib/data/repositories/pixiv_domain_mappers.dart:40`).
5. Bookmark and follow actions update the UI optimistically, call repositories, then roll back on errors (`lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart:56`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart:88`).

**State Management:**
- Global dependency injection uses Riverpod providers in `lib/app/router.dart`, `lib/core/network/dio_provider.dart`, `lib/data/services/*`, and `lib/data/repositories/*`.
- Feature state uses `ChangeNotifier` with immutable state snapshots and `copyWith()` patterns in `lib/ui/features/home/view_models/home_view_model.dart`, `lib/ui/features/search/view_models/search_view_model.dart`, and `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`.
- Auth state is a long-lived `AuthController` that doubles as a router refresh listenable (`lib/ui/features/auth/view_models/auth_controller.dart`, `lib/app/router.dart`).

## Key Abstractions

**Riverpod Providers:**
- Purpose: Register dependency graph nodes and enable test overrides.
- Examples: `routerProvider` in `lib/app/router.dart`, `dioProvider` in `lib/core/network/dio_provider.dart`, `pixivApiServiceProvider` in `lib/data/services/pixiv_api_service.dart`, `homeViewModelProvider` in `lib/ui/features/home/view_models/home_view_model.dart`.
- Pattern: Use `Provider<T>` for stateless dependencies/repositories and `ChangeNotifierProvider<T>` for UI controllers.

**ViewModel State Objects:**
- Purpose: Keep screen state explicit and immutable from the view's perspective.
- Examples: `HomeState` in `lib/ui/features/home/view_models/home_view_model.dart`, `SearchState` and `SearchFilters` in `lib/ui/features/search/view_models/search_view_model.dart`, `ArtworkDetailState` in `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`.
- Pattern: Store one private `_state`, expose a getter, update through `copyWith()` or replacement objects, then call `notifyListeners()`.

**Repositories:**
- Purpose: Hide service/DTO details from UI and view models.
- Examples: `ArtworkRepository` in `lib/data/repositories/artwork_repository.dart`, `SearchRepository` in `lib/data/repositories/search_repository.dart`, `UserRepository` in `lib/data/repositories/user_repository.dart`, `NovelRepository` in `lib/data/repositories/novel_repository.dart`.
- Pattern: Inject service in the constructor, expose domain-returning async methods, and map DTOs with `pixiv_domain_mappers.dart`.

**Service Clients:**
- Purpose: Own Dio configuration, Pixiv endpoint paths, headers, request parsing, token exchange, and token refresh.
- Examples: `PixivApiService` in `lib/data/services/pixiv_api_service.dart`, `PixivAuthService` in `lib/data/services/pixiv_auth_service.dart`, `PixivAccountService` in `lib/data/services/pixiv_account_service.dart`.
- Pattern: Return API DTOs or low-level response wrappers to repositories; do not return widgets or view model state.

**Shared UI Primitives:**
- Purpose: Keep the app's visual system consistent across features.
- Examples: `AppBackground`, `GlassPanel`, `AppButton`, `AppBottomSheetOverlay`, `AppTextField`, `ArtworkCard`, `AppTabShell` in `lib/ui/core/widgets/`.
- Pattern: Prefer reusable primitives before creating feature-local controls.

## Entry Points

**Default app entry:**
- Location: `lib/main.dart`
- Triggers: `flutter run` without a target override.
- Responsibilities: Configure edge-to-edge system UI and run `ProviderScope(child: BysivApp())`.

**Flavor entries:**
- Location: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`
- Triggers: Make targets and Flutter flavor builds in `Makefile`.
- Responsibilities: Initialize `AppConfig` with flavor, app name, and Pixiv API base URL, then run the app.

**App widget:**
- Location: `lib/app/app.dart`
- Triggers: All entry points and widget tests.
- Responsibilities: Install Mix tokens, `ThemeData`, router config, and app title.

**Router:**
- Location: `lib/app/router.dart`
- Triggers: `MaterialApp.router` watches `routerProvider`.
- Responsibilities: Auth redirects, route definitions, detail route parameters, and tab-shell branch routing.

**Platform runners:**
- Location: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`
- Triggers: Platform-specific Flutter build/run commands.
- Responsibilities: Native app launch, manifests, generated plugin registration, app icons, and platform build config.

## Architectural Constraints

- **Threading:** The app uses Flutter's single UI isolate for state and rendering. No explicit isolates or worker threads are present in `lib/`.
- **Global state:** `AppConfig` is a static singleton in `lib/core/config/app_config.dart`. Riverpod providers are module-level singletons throughout `lib/app/`, `lib/core/network/`, `lib/data/services/`, `lib/data/repositories/`, and `lib/ui/features/*/view_models/`.
- **Auth coupling:** `routerProvider` reads `authControllerProvider` and uses it as `refreshListenable`, so auth initialization directly controls routing behavior (`lib/app/router.dart`, `lib/ui/features/auth/view_models/auth_controller.dart`).
- **Feature scope:** `ArtworkDetailViewModel` uses `ChangeNotifierProvider.autoDispose.family`, so detail state is tied to the `illustId` route parameter (`lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`).
- **Circular imports:** No direct circular import chain is detected in the Dart files inspected. Keep imports flowing from UI -> ViewModel -> Repository -> Service/DTO and from Repository -> Domain.
- **Domain purity:** `Artwork` includes `List<Color>` and imports Flutter material (`lib/domain/models/artwork.dart`), so the domain layer is not UI-framework pure.
- **Generated-code directories:** `lib/domain/repositories/`, `lib/domain/use_cases/`, `lib/ui/core/design/`, `lib/ui/core/navigation/`, and `lib/ui/core/shell/` are currently empty and should not be used as established locations until populated intentionally.

## Anti-Patterns

### Calling Services From Views

**What happens:** A view imports a Pixiv service directly, as `AuthScreen` imports `PixivWebAuthMode` from `lib/data/services/pixiv_auth_service.dart`.
**Why it's wrong:** It leaks data-layer types into UI and makes feature views harder to test without service knowledge.
**Do this instead:** Put UI-facing enums/request helpers in a view model or domain-facing abstraction when adding new flows; follow `HomeScreen` -> `HomeViewModel` -> `DiscoverRepository` in `lib/ui/features/home/views/home_screen.dart` and `lib/ui/features/home/view_models/home_view_model.dart`.

### Duplicating Domain Mapping

**What happens:** `DiscoverRepository` has a private `_mapIllust()` while other repositories use `mapIllust()` from `lib/data/repositories/pixiv_domain_mappers.dart`.
**Why it's wrong:** It can create inconsistent `Artwork` mapping across feeds and detail/search screens.
**Do this instead:** Use `pixiv_domain_mappers.dart` for Pixiv DTO to domain conversion in new repositories and repository methods.

### Putting Feature State In Views

**What happens:** Large screens can accumulate stateful UI logic as private widget state, especially in complex screens such as `lib/ui/features/search/views/search_screen.dart`.
**Why it's wrong:** It makes behavior hard to override in tests and splits command logic between widgets and view models.
**Do this instead:** Put async behavior, pagination, filters, debouncing, and mutation state in a `ChangeNotifier` view model like `SearchViewModel` in `lib/ui/features/search/view_models/search_view_model.dart`; keep view-local state only for transient control state required by a widget or bottom sheet.

### Adding Routes Outside AppRoute

**What happens:** Routes can be added as bare strings in `lib/app/router.dart`.
**Why it's wrong:** Tab labels, shell navigation, and route names become inconsistent.
**Do this instead:** Add tab routes to `AppRoute` and `_tabs` in `lib/ui/core/widgets/app_tab_shell.dart`; use named constants from `AppRoute` for tab destinations.

## Error Handling

**Strategy:** Catch errors at view model or service boundaries, convert them to user-facing state or typed exceptions, and keep repositories mostly pass-through.

**Patterns:**
- View models catch broad errors and store `error.toString()` in state fields such as `HomeState.errorMessage`, `SearchState.errorMessage`, and `ArtworkDetailState.errorMessage` (`lib/ui/features/home/view_models/home_view_model.dart`, `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`).
- Auth/account services throw domain-specific exceptions like `PixivAuthException` and `PixivAccountException` (`lib/data/services/pixiv_auth_service.dart`, `lib/data/services/pixiv_account_service.dart`).
- Local stores swallow corrupted or unreadable persisted session data and return safe defaults (`lib/data/repositories/auth_session_store.dart`, `lib/data/repositories/search_recent_store.dart`).
- `PixivApiInterceptor` rejects missing sessions, refreshes OAuth tokens on refreshable errors, retries once, and otherwise forwards Dio errors (`lib/data/services/pixiv_api_interceptor.dart`).

## Cross-Cutting Concerns

**Logging:** Not detected in app code. No logging framework or structured logging calls are present under `lib/`.

**Validation:** Form/input validation is mostly inline in view models and services: empty search submissions are ignored in `lib/ui/features/search/view_models/search_view_model.dart`, empty/missing tokens are rejected in `lib/ui/features/auth/view_models/auth_controller.dart`, and missing sessions throw exceptions in `lib/data/services/pixiv_account_service.dart`.

**Authentication:** `AuthController` owns session lifecycle, `AuthSessionStore` persists tokens with `flutter_secure_storage`, `PixivAuthService` performs OAuth and refresh-token exchange, and `PixivApiInterceptor` injects bearer tokens and refreshes them for Pixiv API requests.

**Theming:** Use `AppColors`, `AppTheme.light`, and `AppMixTheme` from `lib/core/theme/`. New widgets should prefer existing shared primitives under `lib/ui/core/widgets/`.

**Navigation:** Use `go_router` exclusively. Keep auth routes outside `StatefulShellRoute.indexedStack`; keep tabs inside `AppRoute.tabRoutes` and `AppTabShell`.

---

*Architecture analysis: 2026-05-16*
