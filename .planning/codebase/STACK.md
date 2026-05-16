# Technology Stack

**Analysis Date:** 2026-05-16

## Languages

**Primary:**
- Dart 3.11.5 - Flutter application source in `lib/`, tests in `test/`, package configuration in `pubspec.yaml`; SDK constraint is `>=3.11.5 <4.0.0` in `pubspec.lock`.

**Secondary:**
- Kotlin DSL / Gradle - Android build configuration in `android/build.gradle.kts`, `android/settings.gradle.kts`, and `android/app/build.gradle.kts`.
- XML / plist / HTML / JSON - Platform metadata and manifests in `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, `web/index.html`, and `web/manifest.json`.
- YAML - Flutter package and CI configuration in `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/build-prod.yml`.

## Runtime

**Environment:**
- Flutter 3.41.9 stable - recorded in `.metadata`, required by `pubspec.lock`, and used by `.github/workflows/build-prod.yml`.
- Dart SDK 3.11.5 - bundled with Flutter 3.41.9 and required by `pubspec.yaml`.
- Android toolchain - Gradle 8.14 from `android/gradle/wrapper/gradle-wrapper.properties`, Android Gradle Plugin 8.11.1 and Kotlin Android plugin 2.2.20 in `android/settings.gradle.kts`, Java 17 in `android/app/build.gradle.kts`.

**Package Manager:**
- Flutter pub - dependencies declared in `pubspec.yaml`.
- Lockfile: present at `pubspec.lock`.

## Frameworks

**Core:**
- Flutter 3.41.9 - cross-platform app framework; entrypoints are `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, and `lib/main_prod.dart`.
- hooks_riverpod 2.6.1 / riverpod 2.6.1 - dependency injection and state management; providers include `lib/app/router.dart`, `lib/core/network/dio_provider.dart`, `lib/data/services/pixiv_api_service.dart`, and `lib/data/repositories/auth_session_store.dart`.
- go_router 17.2.3 - declarative routing with `StatefulShellRoute.indexedStack` in `lib/app/router.dart`.
- mix 2.0.2 / mix_annotations 2.0.0 - design token scope in `lib/app/app.dart` and tokens in `lib/core/theme/app_mix_theme.dart`.

**Testing:**
- flutter_test SDK - widget tests in `test/widget_test.dart`.
- flutter_lints 6.0.0 - lint rules included by `analysis_options.yaml`.
- custom_lint 0.7.6 and mix_lint 1.7.0 - declared in `pubspec.yaml`; no dedicated custom lint config file detected.

**Build/Dev:**
- build_runner 2.7.1 - configured for code generation workflows from `pubspec.yaml`.
- freezed 3.2.3 / freezed_annotation 3.1.0 - declared for immutable model generation in `pubspec.yaml`.
- json_serializable 6.11.2 / json_annotation 4.9.0 - declared for JSON serialization in `pubspec.yaml`.
- Gradle 8.14 and Android Gradle Plugin 8.11.1 - Android builds in `android/`.
- GitHub Actions - production APK build and release workflow in `.github/workflows/build-prod.yml`.

## Key Dependencies

**Critical:**
- dio 5.9.2 - HTTP client for Pixiv APIs; configured in `lib/core/network/dio_provider.dart`, `lib/data/services/pixiv_api_service.dart`, `lib/data/services/pixiv_auth_service.dart`, and `lib/data/services/pixiv_account_service.dart`.
- flutter_secure_storage 10.2.0 - persistent secure auth session storage in `lib/data/repositories/auth_session_store.dart`.
- webview_flutter 4.13.1 - Pixiv OAuth/web login flow in `lib/ui/features/auth/views/pixiv_auth_web_view_screen.dart`.
- crypto 3.0.7 - PKCE challenge and Pixiv client header hashing in `lib/data/services/pixiv_auth_service.dart`, `lib/data/services/pixiv_api_interceptor.dart`, and `lib/data/services/pixiv_account_service.dart`.
- shared_preferences 2.5.5 - local recent-search persistence in `lib/data/repositories/search_recent_store.dart`.
- cached_network_image 3.4.1 - remote artwork image loading and caching in `lib/ui/core/widgets/artwork_card.dart`, `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`, and `lib/ui/features/search/views/search_screen.dart`.

**Infrastructure:**
- flutter_animate 4.5.2 - UI motion in `lib/ui/core/widgets/app_tab_shell.dart`, `lib/ui/core/widgets/app_bottom_sheet_overlay.dart`, `lib/ui/features/auth/views/auth_screen.dart`, `lib/ui/features/home/views/home_screen.dart`, and `lib/ui/features/search/views/search_screen.dart`.
- lucide_icons_flutter 3.1.13 - icon set in shared and feature widgets under `lib/ui/`.
- skeletonizer 2.1.3 - loading skeletons in `lib/ui/features/home/views/home_screen.dart`, `lib/ui/features/search/views/search_screen.dart`, and `lib/ui/features/artwork_detail/views/artwork_detail_screen.dart`.
- flutter_form_builder 10.3.0+2 - declared in `pubspec.yaml`; no direct usage detected in `lib/`.
- intl 0.20.2 - declared in `pubspec.yaml`; no direct usage detected in `lib/`.
- flutter_svg 2.3.0 - declared in `pubspec.yaml`; no direct usage detected in `lib/`.
- not_static_icons 0.44.0 - declared in `pubspec.yaml`; no direct usage detected in `lib/`.

## Configuration

**Environment:**
- App flavors are represented by `Flavor` and `AppConfig` in `lib/core/config/app_config.dart`.
- Flavor entrypoints initialize `AppConfig` with `apiBaseUrl: https://app-api.pixiv.net` in `lib/main_dev.dart`, `lib/main_staging.dart`, and `lib/main_prod.dart`.
- The default entrypoint `lib/main.dart` starts `BysivApp` without initializing `AppConfig`; API-backed runs should use a flavor entrypoint or initialize `AppConfig` before any provider reads `lib/core/network/dio_provider.dart`.
- Android product flavors `dev`, `staging`, and `prod` are declared in `android/app/build.gradle.kts`; release signing reads `STORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` from the process environment.
- Secret-like file `github_secret.txt` exists at the repository root and was not read.
- `.env` files: not detected.

**Build:**
- `pubspec.yaml` - package metadata, dependencies, dev dependencies, and Flutter asset/material config.
- `pubspec.lock` - locked pub dependency graph and SDK constraints.
- `analysis_options.yaml` - analyzer rules via `package:flutter_lints/flutter.yaml`.
- `.metadata` - Flutter project metadata, channel, and revision.
- `.flutter-plugins-dependencies` - generated platform plugin dependency map.
- `android/app/build.gradle.kts` - Android namespace, application id, flavors, Java/Kotlin 17, and release signing.
- `android/settings.gradle.kts` - Flutter Gradle plugin loader, Android Gradle Plugin, Kotlin plugin, and plugin repositories.
- `.github/workflows/build-prod.yml` - tagged release APK build and GitHub release publishing.

## Platform Requirements

**Development:**
- Flutter 3.41.9 stable with Dart 3.11.5.
- Run `flutter pub get` after dependency changes.
- Android development requires Java 17, Gradle wrapper from `android/gradle/wrapper/gradle-wrapper.properties`, and a generated `android/local.properties` with `flutter.sdk`.
- Networked Pixiv flows require Android internet permission from `android/app/src/main/AndroidManifest.xml`; debug/profile manifests also include internet permission in `android/app/src/debug/AndroidManifest.xml` and `android/app/src/profile/AndroidManifest.xml`.
- macOS debug profile includes `com.apple.security.network.server` in `macos/Runner/DebugProfile.entitlements`; `com.apple.security.network.client` is not detected in macOS entitlements.

**Production:**
- Android APK production target is `prod` flavor using `lib/main_prod.dart`, built by `.github/workflows/build-prod.yml` with `flutter build apk --flavor prod -t lib/main_prod.dart --release`.
- GitHub Actions release builds require repository secrets `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, and `STORE_PASSWORD`.
- Hosting/app distribution beyond GitHub Release artifact upload is not detected.

---

*Stack analysis: 2026-05-16*
