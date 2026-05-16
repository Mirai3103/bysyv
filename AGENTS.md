# AGENTS.md

Guidance for coding agents working in this Flutter repo.

## Project Snapshot

- App name/package: `bysiv`.
- Product context: unofficial mobile client for `pixiv.com`, an art, manga, novel, and creator discovery platform similar to Instagram for artists.
- Treat Pixiv integration as unofficial/reverse-engineered client work. Keep auth/session handling careful, avoid logging tokens, and prefer isolated API/service changes over scattering Pixiv protocol details through UI code.
- Flutter app using Riverpod (`hooks_riverpod`), `go_router`, `mix`, `flutter_animate`, `dio`, `cached_network_image`, `webview_flutter`, `flutter_secure_storage`, and `lucide_icons_flutter`.
- Entry widgets:
  - `lib/main.dart`: default entry.
  - `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`: flavor-style entries.
- App shell/theme/router live in `lib/app/` and `lib/core/theme/`.
- Current initial route is `/auth`; `/` redirects to `/auth`.
- Main tab shell starts at `/home` and uses `StatefulShellRoute.indexedStack`.

## Important Commands

Run these before handing off Dart changes:

```sh
dart format <changed dart files>
flutter analyze
flutter test
```

Use `rg` for searching. Avoid broad generated-file churn.

## Source Layout

- `lib/app/app.dart`: `MaterialApp.router`, `MixScope`, app theme setup.
- `lib/app/router.dart`: all route definitions and `AppRoute` enum.
- `lib/core/config/app_config.dart`: environment/config values.
- `lib/core/network/dio_provider.dart`: shared Dio provider setup.
- `lib/core/theme/`: color/theme/mix tokens. Prefer existing `AppColors`, `AppTheme`, and Mix theme helpers.
- `lib/data/models/`: Pixiv API DTOs and generated-style model classes.
- `lib/data/services/`: Pixiv API, auth, account services, and Dio interceptors.
- `lib/data/repositories/`: repository layer, domain mapping, session/search persistence.
- `lib/domain/models/`: app-facing artwork, creator, tag, auth, comment, novel, and feed models.
- `lib/ui/core/widgets/`: shared UI primitives.
  - `AppBackground`: radial app background.
  - `GlassPanel`: reusable glass card/panel.
  - `AppButton`: shared ripple button with press-scale feedback; variants: `primary`, `secondary`, `ghost`.
  - `AppBottomSheetOverlay`: shared glass bottom sheet overlay with blur backdrop and slide-up animation.
  - `AppTextField`: shared labeled input field, supports icon, password, multiline, monospace.
  - `AppTabShell`: persistent bottom tab shell/nav.
  - `ArtworkCard`: artwork tile/card.
- `lib/ui/features/auth/`: Pixiv auth UI, controller, and WebView auth flow.
- `lib/ui/features/home/`: discovery/home feed UI and view model.
- `lib/ui/features/search/`: artwork/user search UI and view model.
- `lib/ui/features/artwork_detail/`: artwork detail UI and view model.
- `lib/ui/features/placeholders/`: temporary placeholder screens for unfinished tabs.

## Routing Notes

- Keep auth outside the tab shell.
- `AppRoute.auth` is `/auth` and is the initial route.
- Tab routes are:
  - `/home`
  - `/search`
  - `/news`
  - `/notifications`
  - `/profile`
- Artwork detail and auth WebView routes should stay outside tab branch state when they represent modal or full-screen flows.
- The tab shell uses `StatefulNavigationShell.goBranch`.
- Some non-Home tabs may still be placeholders; do not build unrelated tabs while working on a focused feature.

## Pixiv Domain Rules

- Keep Pixiv API details inside `lib/data/services/` and `lib/data/repositories/`.
- Convert API DTOs to app-facing domain models in repository/mapping code before they reach UI.
- Store access/refresh/session material only through `AuthSessionStore` and secure storage patterns already in the repo.
- Do not print tokens, authorization headers, cookies, refresh responses, or full authenticated URLs.
- Use `cached_network_image`/existing image widgets for remote artwork previews so loading, caching, and error states remain consistent.
- When adding feed/search/detail behavior, preserve creator attribution, artwork title, tags, bookmark state, and age-sensitive metadata where available.
- Be conservative with network retries and pagination. Pixiv endpoints can rate-limit or reject unofficial clients.

## UI Patterns

- Prefer shared widgets from `lib/ui/core/widgets` before adding feature-local copies.
- Use `lucide_icons_flutter` for new app icons when available.
- Use `flutter_animate` for entrance/sheet motion; avoid long-running repeat animations in widget-tested flows unless tests account for them.
- Keep the palette aligned with `AppColors`; avoid introducing unrelated color systems.
- Use `AppButton` for tappable CTAs so ripple and press feedback stay consistent.
- Use `AppBottomSheetOverlay` for glass bottom sheets.
- Use `AppTextField` for labeled form fields.
- For artwork-heavy screens, prioritize image density, creator identity, readable titles/tags, and fast scanning over marketing-style hero layouts.
- Keep text and controls responsive; avoid layouts that crop long artwork titles, usernames, or translated tag names.

## State And Data Patterns

- Prefer Riverpod providers/view models over direct service calls from widgets.
- Keep widget files focused on rendering and interaction wiring.
- Keep async loading/error/empty states explicit in view models or screen state branches.
- Reuse existing repository/service boundaries before adding new abstractions.
- If changing API models, check whether generated files or serializers need `build_runner`.

## Testing Notes

- `test/widget_test.dart` covers:
  - Auth as the entry screen.
  - Auth sheet interactions and success state.
  - Home rendering when pumped directly.
  - Home filter pill interaction.
  - Tab shell navigation after routing to `/home`.
- Add focused widget tests for new screens/interactions when practical.
- Mock repository/provider boundaries rather than hitting Pixiv network APIs in tests.
- If adding repeat animations, avoid `pumpAndSettle` deadlocks in tests.

## Working Rules

- Do not revert unrelated user changes.
- Keep edits scoped to the requested feature.
- Prefer existing architecture and shared widgets over new parallel abstractions.
- Do not rename the app/package casually; `bysiv` is the current package name.
- Do not introduce new global color, routing, networking, or persistence systems unless the existing one cannot support the change.
- When adding public/shared widgets, make them small, clearly named, and flexible enough for current use cases without over-designing.
