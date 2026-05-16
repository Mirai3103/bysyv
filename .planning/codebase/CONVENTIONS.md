# Coding Conventions

**Analysis Date:** 2026-05-16

## Naming Patterns

**Files:**
- Use Dart snake_case filenames for source and tests: `lib/ui/features/home/view_models/home_view_model.dart`, `lib/data/repositories/auth_session_store.dart`, `test/widget_test.dart`.
- Place feature UI under plural role directories: `lib/ui/features/search/views/search_screen.dart` and `lib/ui/features/search/view_models/search_view_model.dart`.
- Place shared app primitives under `lib/ui/core/widgets/` with `app_` prefixes when they are app-wide controls: `lib/ui/core/widgets/app_button.dart`, `lib/ui/core/widgets/app_text_field.dart`, `lib/ui/core/widgets/app_bottom_sheet_overlay.dart`.
- Place domain models under `lib/domain/models/` and Pixiv transport/API models under `lib/data/models/`: `lib/domain/models/artwork.dart`, `lib/data/models/pixiv_common_models.dart`.

**Functions:**
- Use lowerCamelCase for public methods and private helper methods: `loadRecommended()` in `lib/ui/features/home/view_models/home_view_model.dart`, `_loadResults()` in `lib/ui/features/search/view_models/search_view_model.dart`, `_postToken()` in `lib/data/services/pixiv_auth_service.dart`.
- Use verb-first async method names for commands and loading flows: `refresh()`, `selectFilter()`, `toggleBookmark()`, `exchangeAuthorizationCode()`.
- Use `map...` naming for transformation helpers in repository/model mapping code: `mapIllust`, `mapPage`, and `mapArtworkDetail` are consumed from `lib/data/repositories/artwork_repository.dart`.

**Variables:**
- Use lowerCamelCase for locals and fields: `activeFilter`, `errorMessage`, `isLoadingMore`, `submittedQuery`.
- Use private underscore fields for injected dependencies and mutable internals: `_repository` in `lib/ui/features/home/view_models/home_view_model.dart`, `_authService` in `lib/ui/features/auth/view_models/auth_controller.dart`, `_dio` in `lib/data/services/pixiv_auth_service.dart`.
- Use `final` for injected collaborators and immutable locals; use `var` only for simple mutable internal state such as `_pressed` in `lib/ui/core/widgets/app_button.dart` and `_autocompleteRequest` in `lib/ui/features/search/view_models/search_view_model.dart`.

**Types:**
- Use PascalCase for widgets, controllers, services, repositories, state objects, exceptions, and enums: `BysivApp`, `AuthController`, `PixivAuthService`, `ArtworkRepository`, `SearchState`, `PixivAuthException`, `SearchResultTab`.
- Use private widget/state classes with leading underscores when scoped to one file: `_AppButtonState` in `lib/ui/core/widgets/app_button.dart`, `_ResultHeaderSliver` in `lib/ui/features/search/views/search_screen.dart`.
- Use immutable state classes annotated with `@immutable` and `copyWith` for view model state: `HomeState` in `lib/ui/features/home/view_models/home_view_model.dart`, `ArtworkDetailState` in `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`, `SearchState` in `lib/ui/features/search/view_models/search_view_model.dart`.
- Use enum values as lowerCamelCase nouns with labels when display text is needed: `HomeFilter.recommend('Recommend')` in `lib/ui/features/home/view_models/home_view_model.dart`, `AppRoute.auth('/auth', 'Auth')` in `lib/app/router.dart`.

## Code Style

**Formatting:**
- Use `dart format` with standard Dart formatting. The repo exposes `make format`, which runs `dart format lib test` from `Makefile`.
- Keep trailing commas in multi-line constructors, widget trees, lists, and method calls so `dart format` produces stable vertical layout. Examples: `ProviderScope(overrides: [...], child: const BysivApp())` in `test/widget_test.dart` and `ArtworkDetail(...)` in `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`.
- Prefer `const` constructors and literals wherever inputs are compile-time constants: `const ProviderScope(child: BysivApp())` in `lib/main.dart`, `const HomeState(...)` in `lib/ui/features/home/view_models/home_view_model.dart`, `const []` fallbacks in `lib/data/models/pixiv_common_models.dart`.

**Linting:**
- Use `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`.
- Keep the default Flutter lint rule set active; `analysis_options.yaml` does not enable custom per-rule overrides.
- Use `flutter analyze` or `make analyze` before handoff. `Makefile` defines the canonical target.
- `mix_lint` and `custom_lint` are dependencies in `pubspec.yaml`, but no custom lint runner or custom lint configuration is detected in `analysis_options.yaml`.

## Import Organization

**Order:**
1. Dart SDK imports first, when present: `dart:async` in `lib/ui/features/search/view_models/search_view_model.dart`, `dart:convert` in `lib/data/repositories/auth_session_store.dart`.
2. Package imports next: Flutter/Riverpod/Dio/etc. imports in `lib/app/app.dart`, `lib/core/network/dio_provider.dart`, and `test/widget_test.dart`.
3. Relative project imports last in `lib/` source files: `../../domain/models/auth_session.dart` in `lib/data/repositories/auth_session_store.dart`, `../../../../data/repositories/search_repository.dart` in `lib/ui/features/search/view_models/search_view_model.dart`.
4. Tests use package imports for app code rather than relative imports: `package:bysiv/app/app.dart` and `package:bysiv/ui/features/home/views/home_screen.dart` in `test/widget_test.dart`.

**Path Aliases:**
- App source uses package imports in tests: `package:bysiv/...` in `test/widget_test.dart`.
- App source under `lib/` uses relative imports rather than a configured alias: `../core/theme/app_theme.dart` in `lib/app/app.dart`, `../../domain/models/artwork.dart` in `lib/data/repositories/artwork_repository.dart`.
- No custom alias configuration is detected in `analysis_options.yaml` or `pubspec.yaml`.

## Error Handling

**Patterns:**
- View models catch repository/service failures, store `errorMessage: error.toString()`, and expose boolean getters like `hasError`: `lib/ui/features/home/view_models/home_view_model.dart`, `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`.
- Authentication wraps lower-level service errors into user-facing controller state. `AuthController._authenticate()` in `lib/ui/features/auth/view_models/auth_controller.dart` sets `_status`, clears `_session` on failure, and stores `_errorMessage`.
- Service-specific exception classes implement `Exception` and override `toString()` to return only the message: `PixivAuthException` in `lib/data/services/pixiv_auth_service.dart`.
- Recoverable local failures can be swallowed when the feature remains usable. `SearchViewModel.initialize()` catches recent-search load failures and continues in `lib/ui/features/search/view_models/search_view_model.dart`.
- Storage decode/load failures return `null` instead of throwing to callers: `AuthSessionStore.load()` in `lib/data/repositories/auth_session_store.dart`.
- JSON parsing uses defensive casts and default values instead of throwing for missing fields: `PixivImageUrls.fromJson()`, `PixivTag.fromJson()`, and `PixivIllust.fromJson()` in `lib/data/models/pixiv_common_models.dart`.

## Logging

**Framework:** Not detected

**Patterns:**
- No app-wide logger is configured in `pubspec.yaml` or used in `lib/`.
- Do not introduce `print()` for application logging; `analysis_options.yaml` inherits Flutter lints where `avoid_print` remains enabled.
- Surface operational failures through state (`errorMessage`, `resultsErrorMessage`) and UI retry paths instead of logging-only behavior. Follow `lib/ui/features/search/view_models/search_view_model.dart`.

## Comments

**When to Comment:**
- Use comments sparingly for non-obvious behavioral decisions. Example: `SearchViewModel.initialize()` explains why recent-search storage failures are ignored in `lib/ui/features/search/view_models/search_view_model.dart`.
- Avoid comments that restate widget or method names. Most files rely on clear names instead: `lib/ui/core/widgets/app_button.dart`, `lib/data/repositories/artwork_repository.dart`.

**JSDoc/TSDoc:**
- Not applicable. This is a Dart/Flutter project and no Dart doc comment convention is currently established in `lib/` or `test/`.
- Public/shared widgets are named clearly rather than documented with `///` comments: `AppButton`, `AppTextField`, and `GlassPanel` in `lib/ui/core/widgets/`.

## Function Design

**Size:** Keep view model public methods focused on a single UI action or lifecycle event. Use private helpers for branching and API-specific work: `_loadArtwork()` in `lib/ui/features/home/view_models/home_view_model.dart`, `_loadResults()` and `_filterArtwork()` in `lib/ui/features/search/view_models/search_view_model.dart`.

**Parameters:** Prefer named required parameters for constructors and API methods with more than one input: `HomeViewModel({required DiscoverRepository repository})`, `ArtworkRepository.addBookmark({required String illustId, ...})`, `PixivAuthService.exchangeAuthorizationCode({required String code, required String codeVerifier})`.

**Return Values:** Use `Future<T>` for async repository/service calls and UI actions. Use nullable return types for missing remote resources: `Future<Artwork?> detail(String illustId)` in `lib/data/repositories/artwork_repository.dart`, `Future<AuthSession?> load()` in `lib/data/repositories/auth_session_store.dart`.

## Module Design

**Exports:** No package-level export barrels are detected. Import concrete files directly: `lib/app/app.dart`, `lib/app/router.dart`, `lib/data/repositories/search_repository.dart`.

**Barrel Files:** Not used. Add new files under the existing feature/core/data/domain directory and import the concrete file where needed.

**Provider Pattern:** Define Riverpod providers near the class they construct. Examples: `homeViewModelProvider` in `lib/ui/features/home/view_models/home_view_model.dart`, `authControllerProvider` in `lib/ui/features/auth/view_models/auth_controller.dart`, `dioProvider` in `lib/core/network/dio_provider.dart`.

**State Pattern:** Keep mutable state private inside `ChangeNotifier` view models, expose immutable snapshots through getters, then call `notifyListeners()` after state changes. Follow `HomeViewModel.state` in `lib/ui/features/home/view_models/home_view_model.dart` and `SearchViewModel.state` in `lib/ui/features/search/view_models/search_view_model.dart`.

**UI Pattern:** Prefer shared widgets from `lib/ui/core/widgets/` before adding feature-local copies. Use `AppButton` for CTAs, `AppTextField` for labeled inputs, `AppBottomSheetOverlay` for glass sheets, and `ArtworkCard` for artwork tiles.

---

*Convention analysis: 2026-05-16*
