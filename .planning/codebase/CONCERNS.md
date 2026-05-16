# Codebase Concerns

**Analysis Date:** 2026-05-16

## Tech Debt

**Large feature view files:**
- Issue: Feature screens contain view composition, local state, routing callbacks, scroll behavior, filtering UI, result rendering, and many private widgets in one file.
- Files: `lib/ui/features/search/views/search_screen.dart` (1,527 lines), `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart` (1,026 lines)
- Impact: Changes to search or artwork detail have a high merge-conflict and regression surface. Small UI changes require navigating very large files, and widget-level reuse/testing is harder because most components are private to the file.
- Fix approach: Split by stable UI regions before adding new behavior. For search, move `_SearchHeader`, result tab/header widgets, filter sheet widgets, and result row/tile widgets into `lib/ui/features/search/widgets/`. For artwork detail, move page display, metadata, action bar, comments, and related grid into `lib/ui/features/artwork_detail/widgets/`.

**Monolithic Pixiv API service:**
- Issue: `PixivApiService` owns every endpoint category, request helper, pagination helper, and response parsing path in one class.
- Files: `lib/data/services/pixiv_api_service.dart`
- Impact: Endpoint-specific changes can accidentally affect unrelated API areas. The class has weak internal boundaries between illust, novel, user, search, settings, comments, and pagination behavior.
- Fix approach: Keep shared Dio/request helpers in `lib/data/services/pixiv_api_service.dart` or a small `PixivApiClient`, then extract endpoint groups such as `PixivIllustService`, `PixivNovelService`, `PixivSearchService`, and `PixivUserService` under `lib/data/services/`. Repositories should depend on only the endpoint surface they need.

**Duplicated Pixiv client header/signature logic:**
- Issue: Pixiv client headers and hash generation are duplicated across auth, API interception, and account services.
- Files: `lib/data/services/pixiv_auth_service.dart`, `lib/data/services/pixiv_api_interceptor.dart`, `lib/data/services/pixiv_account_service.dart`
- Impact: Client metadata, locale, app version, and hash salt can drift between services. A future Pixiv header change must be applied in multiple places.
- Fix approach: Move header generation into a shared helper such as `lib/data/services/pixiv_client_headers.dart`; inject host and keep OAuth/API/account-specific headers as narrow additions.

**Generated-code dependencies without generated-code usage:**
- Issue: `freezed`, `json_serializable`, `build_runner`, and annotations are present, but models use manual constructors and parsing.
- Files: `pubspec.yaml`, `lib/data/models/pixiv_common_models.dart`, `lib/domain/models/*.dart`
- Impact: Contributors may assume generated immutable/copy/JSON patterns are available, while the codebase actually relies on hand-written models and manual `copyWith` implementations.
- Fix approach: Either introduce generated models consistently for new model-heavy areas, or remove unused generation dependencies and document manual model conventions in codebase docs.

**Placeholder routes remain on primary navigation paths:**
- Issue: Main tabs and deep routes use placeholder screens for non-Home tabs and detail pages.
- Files: `lib/app/router.dart`, `lib/ui/features/placeholders/views/placeholder_screen.dart`
- Impact: `/news`, `/notifications`, `/profile`, `/novels/:novelId`, and `/users/:userId` are routable but not feature-complete. Tests currently assert placeholder behavior for novel/user results rather than real user outcomes.
- Fix approach: Treat each placeholder route as an explicit feature gap. Replace placeholders with real screens or gate the route/action until implementation is ready.

## Known Bugs

**Default app entry does not initialize `AppConfig`:**
- Symptoms: `dioProvider` reads `AppConfig.instance`, but `lib/main.dart` never calls `AppConfig.init()`. Any runtime path that constructs `dioProvider` through the default entrypoint can hit the `AppConfig not initialized` assertion or a null-check failure.
- Files: `lib/main.dart`, `lib/core/config/app_config.dart`, `lib/core/network/dio_provider.dart`
- Trigger: Run the app through `lib/main.dart`, authenticate or restore a session, then reach a feature that uses `PixivApiService`.
- Workaround: Launch through `lib/main_dev.dart`, `lib/main_staging.dart`, or `lib/main_prod.dart`, or initialize a default config in `lib/main.dart`.

**Search recent test fails against current UI:**
- Symptoms: `flutter test` fails in `search tab stores five recent words locally` because `find.byTooltip('Back')` finds zero widgets.
- Files: `test/widget_test.dart`, `lib/ui/features/search/views/search_screen.dart`
- Trigger: Run `flutter test`.
- Workaround: Adjust the test to use an existing control, or add an actual back button/tooltip to `_SearchHeader` when results mode is active.

**Web OAuth callback scheme mismatch risk:**
- Symptoms: `PixivAuthWebViewScreen` only intercepts URLs with the `pixiv` scheme, while `PixivAuthService` sends an HTTPS redirect URI in the token request. If the embedded auth flow returns to the configured HTTPS callback instead of a custom-scheme URL, the screen navigates instead of exchanging the code.
- Files: `lib/data/services/pixiv_auth_service.dart`, `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`
- Trigger: Complete web OAuth in an environment where Pixiv redirects to `https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback?...`.
- Workaround: Handle both the expected HTTPS callback URI and the custom `pixiv:` callback before calling `exchangeAuthorizationCode`.

**Detail loading fails whole screen when comments or related fail:**
- Symptoms: Artwork detail requests the core illust, comments, and related artwork concurrently, then awaits all three. A comments or related failure prevents the core artwork detail from rendering.
- Files: `lib/data/repositories/artwork_repository.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`
- Trigger: Open an artwork detail when `/v3/illust/comments` or `/v2/illust/related` fails but `/v1/illust/detail` succeeds.
- Workaround: Load core detail first, then treat comments and related as optional secondary sections with independent errors.

## Security Considerations

**Hard-coded Pixiv OAuth and account client credentials:**
- Risk: Client IDs, client secret, hash salt, and guest token are committed in source. These values are public to anyone with the repo or built app and cannot be rotated without a release.
- Files: `lib/data/services/pixiv_auth_service.dart`, `lib/data/services/pixiv_api_interceptor.dart`, `lib/data/services/pixiv_account_service.dart`
- Current mitigation: OAuth uses PKCE code verifier generation in `lib/data/services/pixiv_auth_service.dart`; user access/refresh tokens are stored in `flutter_secure_storage` through `lib/data/repositories/auth_session_store.dart`.
- Recommendations: Treat embedded Pixiv app credentials as public client metadata, avoid depending on them as secrets, centralize them in one reviewed config object, and document rotation/release requirements.

**Manual refresh-token entry in UI:**
- Risk: The auth screen accepts raw refresh tokens pasted by users. This can encourage handling long-lived credentials outside OAuth and increases exposure via keyboard suggestions, screenshots, or accidental sharing.
- Files: `lib/ui/features/auth/views/auth_screen.dart`, `lib/ui/features/auth/view_models/auth_controller.dart`, `lib/data/repositories/auth_session_store.dart`
- Current mitigation: UI warns users not to share tokens, and saved sessions use secure storage.
- Recommendations: Prefer browser OAuth as the primary path, mark token input as sensitive/autofill-disabled if retained, and avoid logging or surfacing token values in errors.

**Secret-like file present in repository root:**
- Risk: `github_secret.txt` exists at the project root. Its contents were not read during this audit.
- Files: `github_secret.txt`
- Current mitigation: Not detected.
- Recommendations: Verify this file contains no live credentials, remove it from the repo if it does, rotate any exposed value, and add an explicit ignore pattern for local secret files.

**WebView runs unrestricted JavaScript for OAuth:**
- Risk: The OAuth WebView enables unrestricted JavaScript and navigates non-`pixiv` URLs freely.
- Files: `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`
- Current mitigation: The WebView is scoped to the generated Pixiv auth request URL and only intercepts the callback.
- Recommendations: Restrict navigation to expected Pixiv OAuth/account hosts plus the callback host, and reject unknown schemes/hosts before rendering them inside the auth WebView.

**macOS network entitlements are inconsistent:**
- Risk: Debug profile grants `com.apple.security.network.server` but release does not grant `com.apple.security.network.client`; this can break outbound API/image/WebView requests on sandboxed macOS release builds.
- Files: `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`
- Current mitigation: Android declares `android.permission.INTERNET` in `android/app/src/main/AndroidManifest.xml`.
- Recommendations: Add the network client entitlement to macOS debug/profile/release entitlements when macOS is a supported target, and remove server entitlement unless inbound sockets are required.

## Performance Bottlenecks

**Main-isolate JSON parsing for large API responses:**
- Problem: Pixiv response lists are parsed synchronously on the main isolate.
- Files: `lib/data/services/pixiv_api_service.dart`, `lib/data/models/pixiv_common_models.dart`
- Cause: `_getJson` returns `JsonMap`, and page helpers immediately map large `List` payloads into model objects on the UI isolate.
- Improvement path: Keep current parsing for small responses, but use `compute` or a repository-level isolate parser for large feeds/search pages if scrolling or search shows frame drops.

**Search infinite scroll can call `loadMore` repeatedly near list end:**
- Problem: `_onScroll` calls `loadMore()` whenever `extentAfter < 700`; it does not debounce scroll events.
- Files: `lib/ui/features/search/views/search_screen.dart`, `lib/ui/features/search/view_models/search_view_model.dart`
- Cause: Protection relies on `isLoadingMore` and `isResultsLoading`, but scroll listeners can still schedule extra async calls around state transitions.
- Improvement path: Track the in-flight next URL or add a small scroll throttle in the view model so each `nextUrl` is requested at most once.

**Artwork detail fetch blocks on secondary sections:**
- Problem: Comments and related artwork are loaded before the detail screen can render the main artwork.
- Files: `lib/data/repositories/artwork_repository.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`
- Cause: `detailFull` awaits comments and related after fetching the core illust and returns one combined object.
- Improvement path: Return core detail immediately, then load comments and related through separate view-model states so first meaningful render is not gated by secondary requests.

**Full-resolution image preference can increase memory/network load:**
- Problem: `PixivImageUrls.best` prefers `original` before `large`, `medium`, and `squareMedium`.
- Files: `lib/data/models/pixiv_common_models.dart`, `lib/data/repositories/pixiv_domain_mappers.dart`, `lib/ui/core/widgets/artwork_card.dart`
- Cause: Feed cards and detail pages consume mapped domain image URLs without separate thumbnail/detail size policies.
- Improvement path: Map separate thumbnail, preview, and original URLs in domain models, then use thumbnail/medium URLs for grids and original URLs only for full-detail viewing.

## Fragile Areas

**Auth/session refresh flow:**
- Files: `lib/data/services/pixiv_api_interceptor.dart`, `lib/data/repositories/auth_session_store.dart`, `lib/data/services/pixiv_auth_service.dart`
- Why fragile: Refresh detection depends on a `400` response whose nested error message contains `OAuth`. Failed refresh returns the original error and does not clear an invalid session, so the app can remain in an authenticated-looking state with repeated request failures.
- Safe modification: Add unit tests for missing session, expired access token, failed refresh, successful retry, and invalid refresh token. Clear session or notify `AuthController` on unrecoverable refresh failure.
- Test coverage: Widget tests cover stored-session routing, but no unit tests cover `PixivApiInterceptor` or `AuthSessionStore`.

**Manual JSON parsing and silent defaults:**
- Files: `lib/data/models/pixiv_common_models.dart`, `lib/domain/models/auth_session.dart`, `lib/data/repositories/pixiv_domain_mappers.dart`
- Why fragile: Many parsers coerce missing fields to empty strings, zeroes, false, or empty lists. Required upstream fields can disappear without a visible failure, producing blank IDs, missing images, or incorrect UI state.
- Safe modification: Validate identity fields and critical URLs at parsing boundaries. Return typed failures for malformed required data while keeping optional display fields nullable/defaulted.
- Test coverage: No parser unit tests exist for API model edge cases.

**Provider initialization side effects:**
- Files: `lib/ui/features/home/view_models/home_view_model.dart`, `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`
- Why fragile: Providers call `loadRecommended()`, `initialize()`, and `load()` during provider creation. Async work can race with disposal and makes tests dependent on pump timing.
- Safe modification: Keep `_disposed`/mounted guards for every async `ChangeNotifier`, or migrate load triggers into explicit view lifecycle hooks. Use `autoDispose` intentionally for screen-scoped view models.
- Test coverage: Widget tests cover happy paths with fake repositories, but there are no race/dispose tests for in-flight requests.

**Search state transitions:**
- Files: `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/search/views/search_screen.dart`
- Why fragile: Search tracks query text, submitted query, autocomplete request IDs, active tab, pagination URLs, filters, loading flags, and recent words in one state object. UI also mutates a `TextEditingController` from state during build.
- Safe modification: Add focused unit tests for query change, submit, tab switching, filter reset, stale autocomplete responses, and pagination errors before modifying search behavior.
- Test coverage: `test/widget_test.dart` covers several widget flows but currently fails and does not isolate view-model state transitions.

**Shared mutable Dio interceptors:**
- Files: `lib/data/services/pixiv_api_service.dart`, `lib/core/network/dio_provider.dart`
- Why fragile: `pixivApiServiceProvider` mutates the shared Dio instance by adding a `PixivApiInterceptor` during provider creation. Provider refreshes or overrides can add duplicate interceptors to the same Dio.
- Safe modification: Build the Dio plus interceptor in one provider, or check/remove existing `PixivApiInterceptor` before adding. Test that only one auth interceptor is attached.
- Test coverage: Not covered.

## Scaling Limits

**Single-file widget test suite:**
- Current capacity: 14 widget tests in `test/widget_test.dart`.
- Limit: As features grow, shared setup/fakes and unrelated failures make the whole suite harder to diagnose. One failing search test currently makes `flutter test` fail even though other widget flows pass.
- Scaling path: Split by feature into `test/features/auth/`, `test/features/home/`, `test/features/search/`, and `test/features/artwork_detail/`. Move fakes/builders into `test/helpers/`.

**No integration tests for live Pixiv flows:**
- Current capacity: Widget tests use fake repositories and do not exercise real Dio, WebView auth, secure storage, token refresh, or platform entitlements.
- Limit: OAuth callback handling, refresh retries, network permissions, and parsing regressions can pass local tests but fail on device.
- Scaling path: Add integration tests or manual smoke scripts for auth, persisted session restore, token refresh, search, artwork detail, and image loading.

**Flat endpoint service growth:**
- Current capacity: `lib/data/services/pixiv_api_service.dart` is 725 lines.
- Limit: New Pixiv feature areas will continue expanding one service and one API model file.
- Scaling path: Partition service/model files by endpoint domain before adding large feature groups such as user profile, novels, account settings, or notifications.

## Dependencies at Risk

**Private Pixiv API contract:**
- Risk: The app depends on Pixiv mobile/web API endpoints, Android client headers, client hash salt, and response shapes that are not owned by this project.
- Impact: Auth, search, feeds, images, bookmarks, comments, and user actions can break without compile-time errors.
- Migration plan: Centralize Pixiv constants, add contract tests against recorded responses, and keep fallback UI for endpoint failures. Isolate endpoint changes behind repositories.

**`webview_flutter` auth behavior:**
- Risk: OAuth completion depends on WebView navigation callbacks and platform WebView availability.
- Impact: Login/register can fail on platforms or WebView versions that handle redirects differently.
- Migration plan: Support external browser/deep-link auth as an alternative and test callback handling per platform.

**`flutter_secure_storage` platform behavior:**
- Risk: Session persistence depends on platform keychain/keystore behavior and plugin support.
- Impact: Stored sessions may fail to read/write/clear on specific platforms, causing unexpected logout or invalid authenticated state.
- Migration plan: Add repository tests with fake storage plus device smoke tests for supported platforms; surface storage failures where user action is needed.

## Missing Critical Features

**Real News, Notifications, Profile, User, and Novel screens:**
- Problem: Navigation exists, but screens render placeholders.
- Blocks: Users cannot inspect novel details, user profiles, news, notifications, or profile/account data through the routed destinations.

**Account/session recovery UX:**
- Problem: Failed token refresh does not route to re-authentication or clear invalid sessions.
- Blocks: Users with expired/revoked refresh tokens can get repeated API failures without a clear recovery action.

**API/domain parser validation strategy:**
- Problem: Required fields are often defaulted silently.
- Blocks: The app cannot distinguish valid empty data from malformed upstream responses, making production issues harder to debug.

## Test Coverage Gaps

**Auth and token refresh internals:**
- What's not tested: `PixivAuthService` request payloads/error mapping, `AuthSessionStore` malformed storage handling, and `PixivApiInterceptor` refresh/retry behavior.
- Files: `lib/data/services/pixiv_auth_service.dart`, `lib/data/repositories/auth_session_store.dart`, `lib/data/services/pixiv_api_interceptor.dart`
- Risk: Expired sessions and auth failures can regress without failing tests.
- Priority: High

**Repository and API parsing:**
- What's not tested: Mapping from Pixiv JSON to API models, domain models, pagination, missing required fields, and malformed response behavior.
- Files: `lib/data/models/pixiv_common_models.dart`, `lib/data/repositories/pixiv_domain_mappers.dart`, `lib/data/repositories/*.dart`
- Risk: Upstream API changes can produce blank IDs/images or empty feeds while tests still pass.
- Priority: High

**Search view model edge cases:**
- What's not tested: Stale autocomplete results, pagination duplicate prevention, filter/date/bookmark behavior, error transitions, and tab-specific reset semantics.
- Files: `lib/ui/features/search/view_models/search_view_model.dart`, `lib/ui/features/search/views/search_screen.dart`
- Risk: Search regressions can ship through broad widget tests or get masked by fake repository behavior.
- Priority: Medium

**Artwork detail partial failure behavior:**
- What's not tested: Core detail success with related/comments failure, bookmark failure rollback, follow failure rollback, and empty page URL handling.
- Files: `lib/data/repositories/artwork_repository.dart`, `lib/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`
- Risk: Detail screen can fail entirely or display inconsistent optimistic state.
- Priority: Medium

**Platform capability tests:**
- What's not tested: Android/macOS/iOS network permission behavior, WebView availability, secure storage behavior, and image header behavior.
- Files: `android/app/src/main/AndroidManifest.xml`, `macos/Runner/DebugProfile.entitlements`, `macos/Runner/Release.entitlements`, `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`, `lib/ui/core/widgets/artwork_card.dart`
- Risk: Platform-specific failures are only caught manually.
- Priority: Medium

---

*Concerns audit: 2026-05-16*
