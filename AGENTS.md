# AGENTS.md

Guidance for coding agents working in this Flutter repo.

## Project Snapshot

- App name/package: `bysiv`.
- Flutter app using Riverpod (`hooks_riverpod`), `go_router`, `mix`, `flutter_animate`, `dio`, and `lucide_icons_flutter`.
- Entry widget: `lib/main.dart` -> `ProviderScope` -> `BysivApp`.
- App shell/theme/router live in `lib/app/` and `lib/core/theme/`.
- Current initial route is `/auth`; `/` redirects to `/auth`.
- Main tab shell starts at `/home` and uses `StatefulShellRoute.indexedStack`.

## Important Commands

Run these before handing off changes:

```sh
dart format <changed dart files>
flutter analyze
flutter test
```

Use `rg` for searching. Avoid broad generated-file churn.

## Source Layout

- `lib/app/app.dart`: `MaterialApp.router`, `MixScope`, app theme setup.
- `lib/app/router.dart`: all route definitions and `AppRoute` enum.
- `lib/core/theme/`: color/theme/mix tokens. Prefer existing `AppColors` and `AppTheme`.
- `lib/ui/core/widgets/`: shared UI primitives.
  - `AppBackground`: radial app background.
  - `GlassPanel`: reusable glass card/panel.
  - `AppButton`: shared ripple button with press-scale feedback; variants: `primary`, `secondary`, `ghost`.
  - `AppBottomSheetOverlay`: shared glass bottom sheet overlay with blur backdrop and slide-up animation.
  - `AppTextField`: shared labeled input field, supports icon, password, multiline, monospace.
  - `AppTabShell`: persistent bottom tab shell/nav.
  - `ArtworkCard`: artwork tile/card.
- `lib/ui/features/auth/views/auth_screen.dart`: UI-only auth flow and first screen.
- `lib/ui/features/home/`: Home view + view model.
- `lib/ui/features/placeholders/`: temporary placeholder screens for non-Home tabs.
- `lib/data/`, `lib/domain/`: repository/service/model layer for discover artwork.

## Routing Notes

- Keep auth outside the tab shell.
- `AppRoute.auth` is `/auth` and is the initial route.
- Tab routes are:
  - `/home`
  - `/search`
  - `/news`
  - `/notifications`
  - `/profile`
- The tab shell uses `StatefulNavigationShell.goBranch`.
- Non-Home tabs are currently placeholder screens.

## UI Patterns

- Prefer shared widgets from `lib/ui/core/widgets` before adding feature-local copies.
- Use `lucide_icons_flutter` for new app icons when available.
- Use `flutter_animate` for entrance/sheet motion; avoid long-running repeat animations in widget-tested flows unless tests account for them.
- Keep the palette aligned with `AppColors`; avoid introducing unrelated color systems.
- Use `AppButton` for tappable CTAs so ripple and press feedback stay consistent.
- Use `AppBottomSheetOverlay` for glass bottom sheets.
- Use `AppTextField` for labeled form fields.


## Testing Notes

- `test/widget_test.dart` covers:
  - Auth as the entry screen.
  - Auth sheet interactions and success state.
  - Home rendering when pumped directly.
  - Home filter pill interaction.
  - Tab shell navigation after routing to `/home`.
- If adding repeat animations, avoid `pumpAndSettle` deadlocks in tests.

## Working Rules

- Do not revert unrelated user changes.
- Keep edits scoped to the requested feature.
- Prefer existing architecture and shared widgets over new parallel abstractions.
- When adding public/shared widgets, make them small, documented by clear names, and flexible enough for current use cases without over-designing.
