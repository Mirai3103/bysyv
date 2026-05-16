import 'package:bysiv/data/repositories/discover_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/ui/features/home/view_models/home_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeViewModel', () {
    test('loads recommended artwork on init', () async {
      final vm = HomeViewModel(repository: _OkDiscoverRepository());
      await vm.loadRecommended();

      expect(vm.state.isLoading, isFalse);
      expect(vm.state.artwork, isNotEmpty);
      expect(vm.state.activeFilter, HomeFilter.recommend);
      expect(vm.state.hasError, isFalse);
    });

    test('selectFilter switches active filter and loads artwork', () async {
      final vm = HomeViewModel(repository: _OkDiscoverRepository());
      await vm.loadRecommended();

      await vm.selectFilter(HomeFilter.ranking);
      expect(vm.state.activeFilter, HomeFilter.ranking);
      expect(vm.state.artwork, isNotEmpty);

      await vm.selectFilter(HomeFilter.original);
      expect(vm.state.activeFilter, HomeFilter.original);

      await vm.selectFilter(HomeFilter.following);
      expect(vm.state.activeFilter, HomeFilter.following);
    });

    test('selectFilter is a no-op when filter already active with artwork', () async {
      final vm = HomeViewModel(repository: _OkDiscoverRepository());
      await vm.loadRecommended();

      var notified = 0;
      vm.addListener(() => notified++);
      await vm.selectFilter(HomeFilter.recommend);
      expect(notified, 0);
    });

    test('refresh reloads current filter without showing loading', () async {
      final vm = HomeViewModel(repository: _OkDiscoverRepository());
      await vm.loadRecommended();
      await vm.selectFilter(HomeFilter.ranking);

      await vm.refresh();
      expect(vm.state.activeFilter, HomeFilter.ranking);
      expect(vm.state.isLoading, isFalse);
    });

    test('sets errorMessage when repository throws', () async {
      final vm = HomeViewModel(repository: _ErrorDiscoverRepository());
      await vm.loadRecommended();

      expect(vm.state.hasError, isTrue);
      expect(vm.state.errorMessage, contains('boom'));
      expect(vm.state.artwork, isEmpty);
    });

    test('isEmpty is true when not loading and no artwork and no error', () async {
      final vm = HomeViewModel(repository: _EmptyDiscoverRepository());
      await vm.loadRecommended();

      expect(vm.state.isEmpty, isTrue);
      expect(vm.state.hasError, isFalse);
    });

    test('activeFilterIndex clamps to valid range', () async {
      final vm = HomeViewModel(repository: _OkDiscoverRepository());
      await vm.loadRecommended();
      expect(vm.state.activeFilterIndex, 0);

      await vm.selectFilter(HomeFilter.ranking);
      expect(vm.state.activeFilterIndex, 1);
    });
  });
}

class _OkDiscoverRepository extends DiscoverRepository {
  _OkDiscoverRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<Artwork>> recommendedArtwork() async => Artwork.samples;
  @override
  Future<List<Artwork>> rankingArtwork() async => Artwork.samples;
  @override
  Future<List<Artwork>> originalArtwork() async => Artwork.samples;
  @override
  Future<List<Artwork>> followingArtwork() async => Artwork.samples;
}

class _ErrorDiscoverRepository extends DiscoverRepository {
  _ErrorDiscoverRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<Artwork>> recommendedArtwork() async => throw Exception('boom');
  @override
  Future<List<Artwork>> rankingArtwork() async => throw Exception('boom');
  @override
  Future<List<Artwork>> originalArtwork() async => throw Exception('boom');
  @override
  Future<List<Artwork>> followingArtwork() async => throw Exception('boom');
}

class _EmptyDiscoverRepository extends DiscoverRepository {
  _EmptyDiscoverRepository() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<List<Artwork>> recommendedArtwork() async => [];
  @override
  Future<List<Artwork>> rankingArtwork() async => [];
  @override
  Future<List<Artwork>> originalArtwork() async => [];
  @override
  Future<List<Artwork>> followingArtwork() async => [];
}
