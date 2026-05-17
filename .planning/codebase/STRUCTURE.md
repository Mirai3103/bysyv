# Codebase Structure

**Analysis Date:** 2026-05-16

## Directory Layout

```text
bysyv/
├── lib/                         # Flutter application source
│   ├── main.dart                # Default entry point
│   ├── main_dev.dart            # Dev flavor entry point
│   ├── main_staging.dart        # Staging flavor entry point
│   ├── main_prod.dart           # Prod flavor entry point
│   ├── app/                     # App shell and route graph
│   ├── core/                    # Cross-cutting config, network, theme
│   ├── data/                    # API DTOs, services, repositories, local stores
│   ├── domain/                  # App-facing model types
│   └── ui/                      # Shared widgets and feature UI
├── test/                        # Flutter widget tests and in-memory fakes
├── android/                     # Android platform runner and Gradle config
├── ios/                         # iOS platform runner and Xcode config
├── macos/                       # macOS platform runner and Xcode config
├── linux/                       # Linux platform runner and CMake config
├── windows/                     # Windows platform runner and CMake config
├── web/                         # Web manifest, icons, and HTML shell
├── .codex/skills/               # Local Codex/GSD and Flutter skills
├── .planning/codebase/          # Generated codebase mapping documents
├── pubspec.yaml                 # Flutter dependencies and SDK constraints
├── analysis_options.yaml        # Dart analyzer/lint config
├── Makefile                     # Common run/build/quality commands
└── AGENTS.md                    # Repo-specific coding-agent instructions
```

## Directory Purposes

**`lib/app/`:**
- Purpose: App-level composition and routing.
- Contains: `BysivApp`, `routerProvider`, `AppRoute`, redirect rules, tab branches, and top-level detail routes.
- Key files: `lib/app/app.dart`, `lib/app/router.dart`

**`lib/core/config/`:**
- Purpose: Flavor/runtime configuration.
- Contains: `AppConfig` singleton and `Flavor` enum.
- Key files: `lib/core/config/app_config.dart`

**`lib/core/network/`:**
- Purpose: App-wide HTTP client provider.
- Contains: Dio provider configured from `AppConfig.instance`.
- Key files: `lib/core/network/dio_provider.dart`

**`lib/core/theme/`:**
- Purpose: Central theme and design tokens.
- Contains: `AppColors`, Material `ThemeData`, and Mix token bindings.
- Key files: `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart`, `lib/core/theme/app_mix_theme.dart`

**`lib/data/models/`:**
- Purpose: Pixiv API response models and JSON parsing.
- Contains: DTO classes for common Pixiv payloads, account responses, and recommend responses.
- Key files: `lib/data/models/pixiv_common_models.dart`, `lib/data/models/pixiv_account_models.dart`, `lib/data/models/pixiv_recommend_response.dart`

**`lib/data/services/`:**
- Purpose: External API and OAuth client logic.
- Contains: Pixiv API, OAuth, account, and Dio interceptor classes plus Riverpod providers.
- Key files: `lib/data/services/pixiv_api_service.dart`, `lib/data/services/pixiv_auth_service.dart`, `lib/data/services/pixiv_account_service.dart`, `lib/data/services/pixiv_api_interceptor.dart`

**`lib/data/repositories/`:**
- Purpose: Feature-oriented data access, DTO-to-domain mapping, and local storage adapters.
- Contains: Repository providers/classes, secure session store, recent search store, and shared Pixiv domain mappers.
- Key files: `lib/data/repositories/artwork_repository.dart`, `lib/data/repositories/search_repository.dart`, `lib/data/repositories/user_repository.dart`, `lib/data/repositories/novel_repository.dart`, `lib/data/repositories/discover_repository.dart`, `lib/data/repositories/discovery_repository.dart`, `lib/data/repositories/account_repository.dart`, `lib/data/repositories/auth_session_store.dart`, `lib/data/repositories/search_recent_store.dart`, `lib/data/repositories/pixiv_domain_mappers.dart`

**`lib/domain/models/`:**
- Purpose: App-facing data types consumed by repositories, view models, views, and tests.
- Contains: Plain immutable model classes, pagination wrappers, and auth/session models.
- Key files: `lib/domain/models/artwork.dart`, `lib/domain/models/artwork_detail.dart`, `lib/domain/models/auth_session.dart`, `lib/domain/models/feed_page.dart`, `lib/domain/models/novel.dart`, `lib/domain/models/pixiv_creator.dart`, `lib/domain/models/pixiv_tag.dart`, `lib/domain/models/pixiv_comment.dart`, `lib/domain/models/search_user_result.dart`, `lib/domain/models/trend_tag.dart`, `lib/domain/models/spotlight_article.dart`, `lib/domain/models/bookmark_detail.dart`

**`lib/domain/repositories/`:**
- Purpose: Reserved for domain repository contracts.
- Contains: Empty directory.
- Key files: Not applicable.

**`lib/domain/use_cases/`:**
- Purpose: Reserved for reusable business logic use cases.
- Contains: Empty or not populated in the current scan.
- Key files: Not detected.

**`lib/ui/core/widgets/`:**
- Purpose: Shared UI primitives and shell widgets.
- Contains: Background, glass panel, buttons, text fields, bottom sheets, tab shell, and artwork cards.
- Key files: `lib/ui/core/widgets/app_background.dart`, `lib/ui/core/widgets/glass_panel.dart`, `lib/ui/core/widgets/app_button.dart`, `lib/ui/core/widgets/app_bottom_sheet_overlay.dart`, `lib/ui/core/widgets/app_text_field.dart`, `lib/ui/core/widgets/app_tab_shell.dart`, `lib/ui/core/widgets/artwork_card.dart`

**`lib/ui/core/design/`:**
- Purpose: Reserved shared UI design location.
- Contains: Empty directory.
- Key files: Not applicable.

**`lib/ui/core/navigation/`:**
- Purpose: Reserved shared navigation location.
- Contains: Empty directory.
- Key files: Not applicable.

**`lib/ui/core/shell/`:**
- Purpose: Reserved shared shell location.
- Contains: Empty directory.
- Key files: Not applicable.

**`lib/ui/features/auth/`:**
- Purpose: Authentication UI and state.
- Contains: `AuthController`, auth landing screen, and Pixiv web auth screen.
- Key files: `lib/ui/features/auth/view_models/auth_controller.dart`, `lib/ui/features/auth/views/auth_screen.dart`, `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`

**`lib/ui/features/home/`:**
- Purpose: Home/discover feed.
- Contains: `HomeViewModel`, `HomeState`, `HomeFilter`, and home view.
- Key files: `lib/ui/features/home/view_models/home_view_model.dart`, `lib/ui/features/home/views/home_screen.dart`

**`lib/ui/features/search/`:**
- Purpose: Search, autocomplete, filters, recents, and paged result tabs.
- Contains: `SearchViewModel`, `SearchState`, `SearchFilters`, `SearchScreen`, and bottom-sheet UI.
- Key files: `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/search/views/search_screen.dart`

**`lib/ui/features/artwork_detail/`:**
- Purpose: Artwork detail screen and artwork mutations.
- Contains: `ArtworkDetailViewModel`, `ArtworkDetailState`, and detail view.
- Key files: `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`

**`lib/ui/features/placeholders/`:**
- Purpose: Temporary non-Home tab and detail placeholders.
- Contains: Generic placeholder screen.
- Key files: `lib/ui/features/placeholders/views/placeholder_screen.dart`

**`test/`:**
- Purpose: Widget tests and test doubles.
- Contains: `widget_test.dart` with app routing, auth, home, search, tab-shell, and artwork-detail coverage plus fake repositories/stores.
- Key files: `test/widget_test.dart`

**Platform directories:**
- Purpose: Flutter-generated and platform-specific runner code.
- Contains: Native manifests, Xcode projects, CMake files, app icons, generated plugin registrants, and web shell assets.
- Key files: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/laffy/bysyv/MainActivity.kt`, `ios/Runner/AppDelegate.swift`, `web/index.html`, `linux/runner/main.cc`, `windows/runner/main.cpp`, `macos/Runner/AppDelegate.swift`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Default entry point; configures transparent system bars and runs `BysivApp`.
- `lib/main_dev.dart`: Dev flavor entry with `Flavor.dev` and `Bysiv Dev`.
- `lib/main_staging.dart`: Staging flavor entry with `Flavor.staging` and `Bysiv Staging`.
- `lib/main_prod.dart`: Production flavor entry with `Flavor.prod` and `Bysiv`.

**Routing:**
- `lib/app/router.dart`: All `GoRoute`, `StatefulShellRoute.indexedStack`, redirect, route enum, and route-name definitions.
- `lib/ui/core/widgets/app_tab_shell.dart`: Bottom tab navigation implementation and tab icon mapping.

**Configuration:**
- `pubspec.yaml`: Flutter SDK constraint, runtime dependencies, dev dependencies, and asset/material settings.
- `analysis_options.yaml`: Includes `package:flutter_lints/flutter.yaml`.
- `Makefile`: `flutter pub get`, build runner, flavor run/build targets, `dart format`, `flutter analyze`, and `flutter test`.
- `AGENTS.md`: Repo-specific instructions for agents.
- `lib/core/config/app_config.dart`: Flavor config singleton.
- `lib/core/network/dio_provider.dart`: Dio base options provider.

**Core Logic:**
- `lib/data/services/pixiv_api_service.dart`: Pixiv App API endpoints, Dio calls, DTO page parsing, and next-page helpers.
- `lib/data/services/pixiv_api_interceptor.dart`: Request headers, authorization injection, and token refresh/retry behavior.
- `lib/data/services/pixiv_auth_service.dart`: OAuth web request, authorization-code exchange, password login, and refresh token flow.
- `lib/data/repositories/pixiv_domain_mappers.dart`: Shared DTO-to-domain mappers.
- `lib/data/repositories/artwork_repository.dart`: Artwork feed, detail, related, bookmark, and comments operations.
- `lib/data/repositories/search_repository.dart`: Search/autocomplete/trending result operations.
- `lib/data/repositories/auth_session_store.dart`: Secure auth session persistence.
- `lib/data/repositories/search_recent_store.dart`: SharedPreferences-backed recent search store.

**Feature UI:**
- `lib/ui/features/auth/views/auth_screen.dart`: Entry auth UI.
- `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`: Pixiv web auth UI.
- `lib/ui/features/home/views/home_screen.dart`: Discover/home screen.
- `lib/ui/features/search/views/search_screen.dart`: Search and filters screen.
- `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`: Artwork detail screen.
- `lib/ui/features/placeholders/views/placeholder_screen.dart`: Temporary placeholder screen.

**View Models:**
- `lib/ui/features/auth/view_models/auth_controller.dart`: Auth state and session commands.
- `lib/ui/features/home/view_models/home_view_model.dart`: Home feed filters/loading state.
- `lib/ui/features/search/view_models/search_view_model.dart`: Search state, recents, autocomplete debounce, result tabs, filters, and pagination.
- `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`: Detail loading plus optimistic bookmark/follow mutations.

**Shared Widgets:**
- `lib/ui/core/widgets/app_background.dart`: Shared app background.
- `lib/ui/core/widgets/glass_panel.dart`: Mix-backed glass panel primitive.
- `lib/ui/core/widgets/app_button.dart`: Shared CTA/tappable button.
- `lib/ui/core/widgets/app_bottom_sheet_overlay.dart`: Shared bottom sheet overlay.
- `lib/ui/core/widgets/app_text_field.dart`: Shared labeled input.
- `lib/ui/core/widgets/artwork_card.dart`: Shared artwork tile/card.

**Testing:**
- `test/widget_test.dart`: Current widget test suite with Riverpod provider overrides and in-memory repository/store fakes.

## Naming Conventions

**Files:**
- Use lowercase snake_case for Dart files: `home_view_model.dart`, `pixiv_api_service.dart`, `app_tab_shell.dart`.
- Name feature screens with `_screen.dart`: `auth_screen.dart`, `home_screen.dart`, `search_screen.dart`, `artwork_detail_screen.dart`.
- Name state controllers with `_view_model.dart` except auth, which uses `auth_controller.dart`.
- Name reusable app widgets with `app_*.dart` when app-specific: `app_button.dart`, `app_text_field.dart`, `app_bottom_sheet_overlay.dart`.
- Name repository files with `_repository.dart` and local persistence files with `_store.dart`: `artwork_repository.dart`, `auth_session_store.dart`, `search_recent_store.dart`.
- Name service files with `_service.dart`; interceptors use `_interceptor.dart`: `pixiv_api_service.dart`, `pixiv_api_interceptor.dart`.

**Directories:**
- Feature directories use snake_case singular feature names under `lib/ui/features/`: `auth`, `home`, `search`, `artwork_detail`, `placeholders`.
- Feature subdirectories are `views/` and `view_models/`.
- Layer directories are type-based under `lib/data/` and `lib/domain/`: `models/`, `repositories/`, `services/`, `use_cases/`.
- Shared UI widgets live in `lib/ui/core/widgets/`.

## Where to Add New Code

**New Feature:**
- Primary UI code: `lib/ui/features/<feature_name>/views/<feature_name>_screen.dart`
- View model: `lib/ui/features/<feature_name>/view_models/<feature_name>_view_model.dart`
- Route registration: `lib/app/router.dart`
- Shared navigation icon for a new tab: `lib/ui/core/widgets/app_tab_shell.dart`
- Tests: `test/widget_test.dart` or a new focused file under `test/` using `_test.dart`

**New Tab:**
- Add enum value/path/label to `AppRoute` in `lib/app/router.dart`.
- Add a `StatefulShellBranch` for the tab in `lib/app/router.dart`.
- Add a `_TabDestination`  in `lib/ui/core/widgets/app_tab_shell.dart`.
- Put the tab screen under `lib/ui/features/<feature_name>/views/`.

**New Top-Level Detail Route:**
- Add a `GoRoute` outside `StatefulShellRoute.indexedStack` in `lib/app/router.dart`.
- Put the screen under `lib/ui/features/<feature_name>/views/`.
- Use a `ChangeNotifierProvider.autoDispose.family` view model when route parameters determine state, following `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`.

**New ViewModel:**
- Implementation: `lib/ui/features/<feature_name>/view_models/<feature_name>_view_model.dart`
- Use `ChangeNotifierProvider` or `ChangeNotifierProvider.autoDispose.family`.
- Inject repositories/stores through the provider closure.
- Expose a single immutable state object and command methods; do not expose mutable lists or service clients.

**New Repository:**
- Implementation: `lib/data/repositories/<resource>_repository.dart`
- Provider: top-level `final <resource>RepositoryProvider = Provider<...>((ref) { ... });`
- Inject services through the constructor.
- Return domain models from `lib/domain/models/`.
- Use shared mappers in `lib/data/repositories/pixiv_domain_mappers.dart`; add new mapper functions there when converting Pixiv DTOs.

**New Service/API Endpoint:**
- API calls: add to `lib/data/services/pixiv_api_service.dart` when targeting the main Pixiv API.
- Auth calls: add to `lib/data/services/pixiv_auth_service.dart`.
- Account calls: add to `lib/data/services/pixiv_account_service.dart`.
- DTOs: add to `lib/data/models/`.
- Domain models: add to `lib/domain/models/` only for app-facing shapes.

**New Domain Model:**
- Implementation: `lib/domain/models/<model_name>.dart`
- Keep constructors `const` and fields `final`.
- Add `copyWith()` only when mutation workflows need partial updates, following `lib/domain/models/artwork_detail.dart`.

**New API Model/DTO:**
- Implementation: `lib/data/models/<pixiv_resource>_models.dart` or an existing Pixiv DTO file when the response belongs to `pixiv_common_models.dart`.
- Keep JSON parsing in DTOs, not in views or view models.

**New Shared Widget:**
- Implementation: `lib/ui/core/widgets/<widget_name>.dart`
- Use `AppColors` and existing primitives from `lib/ui/core/widgets/`.
- Keep feature-specific widgets private inside the feature screen file until reused by multiple features.

**New Theme Token:**
- Palette constant: `lib/core/theme/app_colors.dart`
- Material theme use: `lib/core/theme/app_theme.dart`
- Mix token binding: `lib/core/theme/app_mix_theme.dart`

**Utilities:**
- Shared UI helpers: `lib/ui/core/widgets/` if widget-specific.
- Network helpers: `lib/core/network/`.
- Runtime config: `lib/core/config/`.
- Data mappers: `lib/data/repositories/pixiv_domain_mappers.dart`.

## Special Directories

**`.planning/codebase/`:**
- Purpose: Generated codebase maps for GSD planning/execution.
- Generated: Yes.
- Committed: Yes, if the orchestrator chooses to commit planning artifacts.

**`.codex/skills/`:**
- Purpose: Local Codex/GSD workflow and Flutter implementation skills.
- Generated: Managed by local tooling.
- Committed: Present in repo working tree.

**`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`:**
- Purpose: Platform runner code and build configuration.
- Generated: Mostly Flutter-generated with project-specific edits.
- Committed: Yes.

**`build/`, `.dart_tool/`, platform `ephemeral/` directories:**
- Purpose: Flutter build outputs and generated tool state.
- Generated: Yes.
- Committed: No.

**Empty reserved source directories:**
- Purpose: Future structure placeholders.
- Generated: No.
- Committed: Present as directories only if tracked by external tooling.
- Paths: `lib/domain/repositories/`, `lib/ui/core/design/`, `lib/ui/core/navigation/`, `lib/ui/core/shell/`.

---

*Structure analysis: 2026-05-16*
