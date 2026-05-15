.PHONY: help get clean build-runner format analyze test \
        run-dev run-staging run-prod \
        build-apk-dev build-apk-staging build-apk-prod \
        build-aab-prod

# Default target
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup:"
	@echo "  get            flutter pub get"
	@echo "  clean          flutter clean + pub get"
	@echo "  build-runner   run build_runner (code gen)"
	@echo ""
	@echo "Dev:"
	@echo "  run-dev        run app with dev flavor"
	@echo "  run-staging    run app with staging flavor"
	@echo "  run-prod       run app with prod flavor"
	@echo ""
	@echo "Quality:"
	@echo "  format         dart format lib test"
	@echo "  analyze        flutter analyze"
	@echo "  test           flutter test"
	@echo ""
	@echo "Build:"
	@echo "  build-apk-dev      build debug APK (dev)"
	@echo "  build-apk-staging  build debug APK (staging)"
	@echo "  build-apk-prod     build release APK (prod)"
	@echo "  build-aab-prod     build release AAB (prod)"

# ── Setup ────────────────────────────────────────────────────────────────────

get:
	flutter pub get

clean:
	flutter clean
	flutter pub get

build-runner:
	dart run build_runner build --delete-conflicting-outputs

# ── Run ──────────────────────────────────────────────────────────────────────

run-dev:
	flutter run --flavor dev -t lib/main_dev.dart

run-staging:
	flutter run --flavor staging -t lib/main_staging.dart

run-prod:
	flutter run --flavor prod -t lib/main_prod.dart

# ── Quality ──────────────────────────────────────────────────────────────────

format:
	dart format lib test

analyze:
	flutter analyze

test:
	flutter test

# ── Build ────────────────────────────────────────────────────────────────────

build-apk-dev:
	flutter build apk --flavor dev -t lib/main_dev.dart --debug

build-apk-staging:
	flutter build apk --flavor staging -t lib/main_staging.dart --debug

build-apk-prod:
	flutter build apk --flavor prod -t lib/main_prod.dart --release

build-aab-prod:
	flutter build appbundle --flavor prod -t lib/main_prod.dart --release
