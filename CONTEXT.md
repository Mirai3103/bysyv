# CONTEXT.md

## Project Overview

This is `bysiv`, a Flutter-based unofficial Pixiv client. The app provides Pixiv authentication, authenticated API access, artwork discovery, search, artwork detail, bookmarks, comments, and tabbed navigation for common Pixiv surfaces. Some routes are implemented as placeholders while the underlying API/service layer already covers broader Pixiv functionality.

## Tech Stack & Architecture

- **Framework:** Flutter / Dart (`sdk: ^3.11.5`).
- **State management / DI:** `hooks_riverpod` and `riverpod` with explicit `Provider` and `ChangeNotifierProvider` declarations.
- **Navigation:** `go_router`, including auth redirects and `StatefulShellRoute.indexedStack` for tabs.
- **Networking:** `dio` with a Pixiv-specific auth/header interceptor.
- **Persistence:** `flutter_secure_storage` for auth sessions; `shared_preferences` is available for local preferences/history-style state.
- **Models / serialization:** `freezed_annotation`, `json_annotation`, generated JSON model patterns, and hand-written domain mapping.
- **UI libraries:** Material, `mix`, `flutter_hooks`, `cached_network_image`, `webview_flutter`, icon packages, animation/skeleton helpers.

The project follows a layered structure:

1. `data/services` perform raw Pixiv HTTP/auth operations.
2. `data/repositories` expose app-facing data operations and map API DTOs to domain models.
3. `domain/models` contain UI/domain-level entities.
4. `ui/features/*` contain screens and `ChangeNotifier` view models.
5. `app` wires routing and the root app shell.

## Business Logic & Features

### Authentication

- `lib/data/services/pixiv_auth_service.dart` implements Pixiv login, OAuth refresh, PKCE web auth request generation, and required Pixiv Android-style request signing.
- `lib/data/repositories/auth_session_store.dart` persists access/refresh token session data in secure storage.
- `lib/data/services/pixiv_api_interceptor.dart` attaches Pixiv headers and bearer tokens to API calls and refreshes sessions on OAuth-related failures.
- `lib/ui/features/auth` contains auth controller/view logic and Pixiv web auth UI.

### Pixiv API Access

`lib/data/services/pixiv_api_service.dart` centralizes Pixiv endpoints, including:

- recommended, ranking, following, and related illustrations;
- artwork detail, ugoira metadata, series, bookmarks, comments, and replies;
- novels, novel text/web view, ranking, and bookmarks;
- users, following/followers, profiles, and follow actions;
- search, autocomplete, trending tags, spotlight/news-style data;
- pagination through Pixiv `next_url` fields.

API constants in this service define Pixiv filters/restricts/ranking modes such as `for_ios`, `for_android`, `public`, `private`, `all`, `day`, and `week_original`.

### Repositories and Mapping

- `lib/data/repositories/artwork_repository.dart`, `novel_repository.dart`, `search_repository.dart`, `user_repository.dart`, and `discover_repository.dart` provide feature-oriented access to API data.
- `lib/data/repositories/pixiv_domain_mappers.dart` maps Pixiv DTOs into domain models, selects image URLs, strips simple caption HTML, and normalizes creators, tags, bookmark state, comments, and pagination.
- Repository page results are generally mapped from `PixivPage<T>` into app-level feed/page models.

### UI Workflows

- `lib/app/router.dart` starts at `/auth`, redirects authenticated users to `/home`, and redirects unauthenticated users back to auth routes.
- Main tabs are Home, Search, News, Notifications, and Profile. News, notifications, profile, user profile, and novel detail currently route to placeholder screens.
- `lib/ui/features/home` implements a feed with filters such as recommend, ranking, original, and following.
- `lib/ui/features/search` implements recent searches, trending tags, debounced autocomplete, tabbed search results, filters, sorting, and pagination.
- `lib/ui/features/artwork_detail` implements artwork detail-oriented presentation and interactions.

## Directory Structure

```text
lib/
  main.dart                 App entrypoint.
  main_dev.dart             Dev flavor entrypoint.
  main_staging.dart         Staging flavor entrypoint.
  main_prod.dart            Prod flavor entrypoint.
  app/
    app.dart                Root MaterialApp/router setup.
    router.dart             GoRouter routes, auth redirects, tab shell.
  core/
    config/                 Environment and app configuration.
    network/                Dio provider setup.
    theme/                  Color/theme/Mix tokens.
  data/
    models/                 Pixiv API DTOs and JSON models.
    services/               Auth, API, account, and interceptor services.
    repositories/           App-facing repositories, storage, mappers.
  domain/
    models/                 Domain/UI entities.
    use_cases/              Placeholder for use-case layer.
  ui/
    core/widgets/           Shared app widgets and tab shell.
    features/               Feature screens and view models.

test/
  helpers/                  Fakes, Dio helpers, widget pump helpers.
  unit/                     Unit tests for core/data/ui logic.
  widget/                   Widget tests.
```

## Conventions & API Rules

- Prefer small, feature-scoped changes. Match existing Flutter/Riverpod patterns instead of introducing new architecture.
- Providers are named with a `*Provider` suffix and usually construct services/repositories from watched dependencies.
- View models generally extend `ChangeNotifier`; state objects are immutable-style classes with `copyWith`, computed getters, and nullable error strings.
- Repositories should hide Pixiv DTO details from UI code and return domain models or feed/page wrappers.
- Pixiv network calls should go through `PixivApiService` or an existing service layer, not directly from UI/view models.
- Authenticated Pixiv API calls need Pixiv-compatible headers and bearer auth. Use the existing Dio provider/interceptor path unless there is a strong reason not to.
- Pixiv form POST endpoints use `Headers.formUrlEncodedContentType`.
- Pixiv pagination uses returned `next_url` values; keep pagination state in repositories/view models rather than reconstructing URLs in widgets.
- API parsing is defensive: missing or malformed optional Pixiv fields often map to `null`, empty lists, or default booleans.
- Tests use Flutter test tooling with helpers in `test/helpers`; add focused unit or widget tests for behavior changes where practical.
