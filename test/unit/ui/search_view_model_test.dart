import 'package:bysiv/data/repositories/search_recent_store.dart';
import 'package:bysiv/data/repositories/search_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/domain/models/feed_page.dart';
import 'package:bysiv/domain/models/novel.dart';
import 'package:bysiv/domain/models/pixiv_creator.dart';
import 'package:bysiv/domain/models/pixiv_tag.dart';
import 'package:bysiv/domain/models/search_user_result.dart';
import 'package:bysiv/domain/models/trend_tag.dart';
import 'package:bysiv/ui/features/search/view_models/search_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  group('SearchViewModel', () {
    test('initialize loads trending tags', () async {
      final vm = _makeVm();
      await vm.initialize();

      expect(vm.state.trendingTags, isNotEmpty);
      expect(vm.state.isTrendingLoading, isFalse);
      expect(vm.state.hasError, isFalse);
    });

    test('initialize sets errorMessage when trending fails', () async {
      final vm = _makeVm(throwTrending: true);
      await vm.initialize();

      expect(vm.state.hasError, isTrue);
      expect(vm.state.isTrendingLoading, isFalse);
    });

    test('submitSearch transitions to results mode', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');

      expect(vm.state.mode, SearchMode.results);
      expect(vm.state.submittedQuery, 'miku');
      expect(vm.state.artworkResults, isNotEmpty);
    });

    test('submitSearch ignores empty query', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('   ');

      expect(vm.state.mode, SearchMode.idle);
    });

    test('selectRecent submits the word', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.selectRecent('rin');

      expect(vm.state.submittedQuery, 'rin');
      expect(vm.state.mode, SearchMode.results);
    });

    test('selectTrendingTag submits the tag', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.selectTrendingTag(TrendTag(tag: 'landscape', artwork: Artwork.samples.first));

      expect(vm.state.submittedQuery, 'landscape');
    });

    test('selectAutocomplete submits the tag name', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.selectAutocomplete(const PixivTag(name: 'miku original'));

      expect(vm.state.submittedQuery, 'miku original');
    });

    test('clearQuery resets to idle', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');
      vm.clearQuery();

      expect(vm.state.mode, SearchMode.idle);
      expect(vm.state.query, isEmpty);
      expect(vm.state.artworkResults, isEmpty);
    });

    test('backToIdle resets mode and clears error', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');
      vm.backToIdle();

      expect(vm.state.mode, SearchMode.idle);
      expect(vm.state.submittedQuery, isEmpty);
    });

    test('removeRecent removes a word', () async {
      final store = FakeSearchRecentStore(['miku', 'rin']);
      final vm = _makeVm(recentStore: store);
      await vm.initialize();

      await vm.removeRecent('miku');
      expect(vm.state.recentWords, isNot(contains('miku')));
    });

    test('clearRecent empties recent words', () async {
      final store = FakeSearchRecentStore(['miku', 'rin']);
      final vm = _makeVm(recentStore: store);
      await vm.initialize();

      await vm.clearRecent();
      expect(vm.state.recentWords, isEmpty);
    });

    test('setActiveTab switches tab and loads results', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');

      await vm.setActiveTab(SearchResultTab.novel);
      expect(vm.state.activeTab, SearchResultTab.novel);
      expect(vm.state.novelResults, isNotEmpty);

      await vm.setActiveTab(SearchResultTab.user);
      expect(vm.state.activeTab, SearchResultTab.user);
      expect(vm.state.userResults, isNotEmpty);
    });

    test('setActiveTab is no-op for same tab', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');

      var notified = 0;
      vm.addListener(() => notified++);
      await vm.setActiveTab(SearchResultTab.artwork);
      expect(notified, 0);
    });

    test('setSort reloads artwork results', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');

      await vm.setSort('popular_desc');
      expect(vm.state.sort, 'popular_desc');
      expect(vm.state.artworkResults, isNotEmpty);
    });

    test('retryTrending re-initializes', () async {
      final vm = _makeVm();
      await vm.retryTrending();
      expect(vm.state.trendingTags, isNotEmpty);
    });

    test('retryResults reloads current results', () async {
      final vm = _makeVm();
      await vm.initialize();
      await vm.submitSearch('miku');
      await vm.retryResults();
      expect(vm.state.artworkResults, isNotEmpty);
    });

    test('queryChanged with empty string clears autocomplete', () async {
      final vm = _makeVm();
      await vm.initialize();
      vm.queryChanged('');

      expect(vm.state.isAutocompleteLoading, isFalse);
      expect(vm.state.autocompleteTags, isEmpty);
    });
  });
}

SearchViewModel _makeVm({
  bool throwTrending = false,
  SearchRecentStore? recentStore,
}) {
  return SearchViewModel(
    repository: _FakeSearchRepo(throwTrending: throwTrending),
    recentStore: recentStore ?? FakeSearchRecentStore(),
  );
}

class _FakeSearchRepo extends SearchRepository {
  _FakeSearchRepo({this.throwTrending = false})
      : super(apiService: PixivApiService(dio: Dio()));

  final bool throwTrending;

  @override
  Future<List<TrendTag>> trendingIllustTags() async {
    if (throwTrending) throw Exception('trending failed');
    return [TrendTag(tag: 'miku', artwork: Artwork.samples.first)];
  }

  @override
  Future<List<PixivTag>> autocompleteTags(String word) async =>
      [PixivTag(name: word), PixivTag(name: '$word original')];

  @override
  Future<FeedPage<Artwork>> illusts({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNumMin,
    int? bookmarkNumMax,
    int searchAiType = 0,
  }) async => FeedPage(items: [
    Artwork(
      id: 'a-1',
      title: word,
      artist: 'mika',
      bookmarks: 10,
      gradient: const [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
    ),
  ]);

  @override
  Future<FeedPage<Novel>> novels({
    required String word,
    String sort = 'date_desc',
    String searchTarget = 'partial_match_for_tags',
    String? startDate,
    String? endDate,
    int? bookmarkNum,
  }) async => FeedPage(items: [
    Novel(
      id: 'n-1',
      title: word,
      author: const PixivCreator(id: 'u-1', name: 'Aki', account: 'aki'),
      bookmarks: 5,
      pageCount: 1,
      textLength: 1000,
    ),
  ]);

  @override
  Future<FeedPage<SearchUserResult>> userResults(String word) async =>
      const FeedPage(items: [
        SearchUserResult(
          creator: PixivCreator(id: 'u-1', name: 'Mika', account: 'mika'),
          previewArtworks: [],
        ),
      ]);
}
