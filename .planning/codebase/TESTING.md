# Testing Patterns

**Analysis Date:** 2026-05-16

## Test Framework

**Runner:**
- Flutter widget test runner via `flutter_test` from the Flutter SDK.
- Config: Not detected. There is no `flutter_test_config.dart`, `test_config.dart`, `jest.config.*`, or `vitest.config.*`; tests rely on Flutter defaults.
- Current test file: `test/widget_test.dart`.

**Assertion Library:**
- `flutter_test` matchers and finders: `expect`, `find.text`, `find.byTooltip`, `find.byKey`, `find.byType`, `findsOneWidget`, `findsWidgets`, `findsNothing`, `isEmpty`.

**Run Commands:**
```bash
flutter test              # Run all tests
make test                 # Run all tests through Makefile
flutter test --coverage   # Generate Flutter coverage output
```

## Test File Organization

**Location:**
- Tests are stored in the root `test/` directory.
- The current suite is consolidated in `test/widget_test.dart`.
- No `integration_test/`, `test_driver/`, or separate unit-test directories are detected.

**Naming:**
- Test files use Flutter's `_test.dart` suffix: `test/widget_test.dart`.
- Test descriptions are behavior-focused and lower-case phrases: `renders auth welcome as the entry screen`, `switches between shell tabs`, `bookmark button updates artwork detail state`.

**Structure:**
```
test/
└── widget_test.dart      # Widget/routing/search/detail coverage with local fakes
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  testWidgets('renders auth welcome as the entry screen', (tester) async {
    await _pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('pixiv'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
```

**Patterns:**
- Use `testWidgets()` directly; no top-level `group()` blocks are currently used in `test/widget_test.dart`.
- Pump the whole app with `_pumpApp()` for routed behavior through `BysivApp` in `test/widget_test.dart`.
- Pump a single screen with `_pumpHome()` when the test should bypass routing and target a view directly in `test/widget_test.dart`.
- Use `ProviderScope(overrides: [...])` to inject fake repositories and stores in `test/widget_test.dart`.
- Use `await tester.pumpAndSettle()` after app startup, route changes, sheet openings, tab switches, and animations in `test/widget_test.dart`.
- Use targeted `await tester.pump(const Duration(...))` for debounced behavior, such as autocomplete timing in `test/widget_test.dart`.
- Use `await tester.ensureVisible(...)` and `await tester.scrollUntilVisible(...)` before tapping content that may be off-screen in `test/widget_test.dart`.

## Mocking

**Framework:** Manual fakes only

**Patterns:**
```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      discoverRepositoryProvider.overrideWithValue(_FakeDiscoverRepository()),
      artworkRepositoryProvider.overrideWithValue(_FakeArtworkRepository()),
      userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
      searchRepositoryProvider.overrideWithValue(_FakeSearchRepository()),
      searchRecentStoreProvider.overrideWithValue(_MemorySearchRecentStore()),
    ],
    child: const BysivApp(),
  ),
);
```

**What to Mock:**
- Mock repository providers at the Riverpod boundary for widget tests: `discoverRepositoryProvider`, `artworkRepositoryProvider`, `userRepositoryProvider`, `searchRepositoryProvider` in `test/widget_test.dart`.
- Mock local persistence stores when testing session/recent-search behavior: `_MemoryAuthSessionStore` and `_MemorySearchRecentStore` in `test/widget_test.dart`.
- Return deterministic domain objects from fakes: `Artwork.samples`, `FeedPage<Artwork>`, `FeedPage<Novel>`, and `FeedPage<SearchUserResult>` in `test/widget_test.dart`.

**What NOT to Mock:**
- Do not mock Flutter widgets or the router for app-level widget tests. `_pumpApp()` uses the real `BysivApp` and route configuration from `lib/app/app.dart` and `lib/app/router.dart`.
- Do not mock view models when testing user flows. Tests exercise UI through the actual `HomeViewModel`, `SearchViewModel`, `AuthController`, and `ArtworkDetailViewModel` by overriding their lower-level dependencies.
- Avoid live network calls. Fake repositories extend concrete repository classes but override methods that the UI invokes in `test/widget_test.dart`.

## Fixtures and Factories

**Test Data:**
```dart
const _session = AuthSession(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  userId: '123',
  userName: 'Tester',
  account: 'tester',
);
```

**Location:**
- Test fixtures live at the bottom of `test/widget_test.dart` as private classes and constants: `_session`, `_FakeDiscoverRepository`, `_FakeArtworkRepository`, `_FakeSearchRepository`, `_FakeUserRepository`, `_MemoryAuthSessionStore`, `_MemorySearchRecentStore`.
- Shared sample artwork data lives in production model code as `Artwork.samples` in `lib/domain/models/artwork.dart` and is reused by tests.

## Coverage

**Requirements:** None enforced

**View Coverage:**
```bash
flutter test --coverage
```

- No minimum line/branch coverage threshold is configured.
- No CI coverage gate is detected in `.github/` from the quality scan.
- Current widget coverage targets auth entry/routing, home rendering and filters, tab navigation, search autocomplete/recent/results, artwork detail navigation, and bookmark state in `test/widget_test.dart`.

## Test Types

**Unit Tests:**
- Not separately organized. Pure logic in repositories, services, mappers, JSON parsing, and view models is not covered by dedicated unit test files.
- If adding unit tests, place them under `test/` with `_test.dart` names and prefer direct construction of models/services/view models where Flutter rendering is not needed.

**Integration Tests:**
- Not used. No `integration_test/` directory or `integration_test` dev dependency is detected in `pubspec.yaml`.
- App-level routing behavior is currently covered through widget tests that pump `BysivApp` in `test/widget_test.dart`.

**E2E Tests:**
- Not used. No `flutter_driver`, Patrol, or external E2E harness is detected.

## Common Patterns

**Async Testing:**
```dart
await tester.enterText(find.byType(TextField), 'miku');
await tester.pump(const Duration(milliseconds: 350));
await tester.pumpAndSettle();
expect(find.text('miku original'), findsOneWidget);
```

**Error Testing:**
```dart
// No explicit failure-path widget tests are currently present.
// Add fakes that throw from repository methods, then assert visible retry/error UI.
```

**Navigation Testing:**
```dart
await tester.tap(find.byTooltip('Search'));
await tester.pumpAndSettle();
expect(find.text('Trending tags'), findsOneWidget);
```

**Form/Search Submission Testing:**
```dart
await tester.enterText(find.byType(TextField), 'miku');
await tester.testTextInput.receiveAction(TextInputAction.search);
await tester.pumpAndSettle();
expect(find.text('Artwork'), findsOneWidget);
```

**Provider Override Testing:**
- Use `overrideWithValue()` for repositories and stores when pumping app or screen widgets.
- Keep fake classes private to the test file unless multiple test files need the same fake.
- Keep fake return values small and deterministic, as in `_FakeSearchRepository.illusts()` and `_FakeArtworkRepository.detailFull()` in `test/widget_test.dart`.

**Animation Testing:**
- Use `pumpAndSettle()` for existing finite route/sheet/entrance animations.
- If adding long-running repeat animations in `lib/ui/`, avoid unbounded animations in tested flows or use bounded `pump()` durations in tests to prevent `pumpAndSettle()` deadlocks.

---

*Testing analysis: 2026-05-16*
