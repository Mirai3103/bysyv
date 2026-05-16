import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/search_recent_store.dart';
import '../../../../data/repositories/search_repository.dart';
import '../../../../domain/models/artwork.dart';
import '../../../../domain/models/novel.dart';
import '../../../../domain/models/pixiv_tag.dart';
import '../../../../domain/models/search_user_result.dart';
import '../../../../domain/models/trend_tag.dart';

final searchViewModelProvider = ChangeNotifierProvider<SearchViewModel>((ref) {
  final viewModel = SearchViewModel(
    repository: ref.watch(searchRepositoryProvider),
    recentStore: ref.watch(searchRecentStoreProvider),
  );
  viewModel.initialize();
  return viewModel;
});

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required SearchRepository repository,
    required SearchRecentStore recentStore,
  }) : _repository = repository,
       _recentStore = recentStore;

  final SearchRepository _repository;
  final SearchRecentStore _recentStore;

  Timer? _autocompleteTimer;
  var _autocompleteRequest = 0;
  var _disposed = false;

  SearchState _state = const SearchState();
  SearchState get state => _state;

  Future<void> initialize() async {
    _state = _state.copyWith(isTrendingLoading: true, errorMessage: null);
    _notify();

    try {
      final recent = await _recentStore.load();
      _state = _state.copyWith(recentWords: recent);
      _notify();
    } catch (_) {
      // Recent search is a local convenience; keep the screen usable if it
      // cannot be read.
    }

    try {
      final trending = await _repository.trendingIllustTags();
      _state = _state.copyWith(
        trendingTags: trending,
        isTrendingLoading: false,
      );
    } catch (error) {
      _state = _state.copyWith(
        isTrendingLoading: false,
        errorMessage: error.toString(),
      );
    }
    _notify();
  }

  void queryChanged(String query) {
    final trimmedQuery = query.trim();
    _state = _state.copyWith(query: query, autocompleteTags: const []);
    _notify();

    _autocompleteTimer?.cancel();
    _autocompleteRequest++;
    if (trimmedQuery.isEmpty) {
      _state = _state.copyWith(isAutocompleteLoading: false);
      _notify();
      return;
    }

    _state = _state.copyWith(isAutocompleteLoading: true);
    _notify();

    final request = _autocompleteRequest;
    _autocompleteTimer = Timer(const Duration(milliseconds: 300), () {
      _loadAutocomplete(trimmedQuery, request);
    });
  }

  Future<void> submitSearch([String? word]) async {
    final keyword = (word ?? _state.query).trim();
    if (keyword.isEmpty) return;

    final recent = await _recentStore.saveWord(keyword);
    _autocompleteTimer?.cancel();
    _autocompleteRequest++;
    _state = _state.copyWith(
      query: keyword,
      recentWords: recent,
      autocompleteTags: const [],
      isAutocompleteLoading: false,
      mode: SearchMode.results,
      submittedQuery: keyword,
    );
    _notify();
    await _loadResults(reset: true);
  }

  Future<void> selectRecent(String word) => submitSearch(word);

  Future<void> selectTrendingTag(TrendTag tag) => submitSearch(tag.tag);

  Future<void> selectAutocomplete(PixivTag tag) => submitSearch(tag.name);

  Future<void> removeRecent(String word) async {
    final recent = await _recentStore.remove(word);
    _state = _state.copyWith(recentWords: recent);
    _notify();
  }

  Future<void> clearRecent() async {
    await _recentStore.clear();
    _state = _state.copyWith(recentWords: const []);
    _notify();
  }

  Future<void> retryTrending() => initialize();

  Future<void> retryResults() => _loadResults(reset: true);

  void backToIdle() {
    _state = _state.copyWith(
      mode: SearchMode.idle,
      submittedQuery: '',
      resultsErrorMessage: null,
    );
    _notify();
  }

  void clearQuery() {
    _autocompleteTimer?.cancel();
    _autocompleteRequest++;
    _state = _state.copyWith(
      query: '',
      autocompleteTags: const [],
      isAutocompleteLoading: false,
      mode: SearchMode.idle,
      submittedQuery: '',
      artworkResults: const [],
      novelResults: const [],
      userResults: const [],
      artworkNextUrl: null,
      novelNextUrl: null,
      userNextUrl: null,
      resultsErrorMessage: null,
    );
    _notify();
  }

  Future<void> setActiveTab(SearchResultTab tab) async {
    if (tab == _state.activeTab) return;
    _state = _state.copyWith(activeTab: tab, resultsErrorMessage: null);
    _notify();

    final needsLoad = switch (tab) {
      SearchResultTab.artwork => _state.artworkResults.isEmpty,
      SearchResultTab.novel => _state.novelResults.isEmpty,
      SearchResultTab.user => _state.userResults.isEmpty,
    };
    if (needsLoad) await _loadResults(reset: true);
  }

  Future<void> setSort(String sort) async {
    if (sort == _state.sort || _state.activeTab == SearchResultTab.user) {
      return;
    }
    _state = _state.copyWith(sort: sort);
    _notify();
    await _loadResults(reset: true);
  }

  Future<void> applyFilters(SearchFilters filters) async {
    if (filters == _state.filters || _state.activeTab == SearchResultTab.user) {
      return;
    }
    _state = _state.copyWith(filters: filters);
    _notify();
    await _loadResults(reset: true);
  }

  Future<void> loadMore() async {
    if (_state.isLoadingMore || _state.isResultsLoading) return;
    final nextUrl = _activeNextUrl;
    if (nextUrl == null || nextUrl.isEmpty) return;

    _state = _state.copyWith(isLoadingMore: true, resultsErrorMessage: null);
    _notify();

    try {
      switch (_state.activeTab) {
        case SearchResultTab.artwork:
          final page = await _repository.nextIllusts(nextUrl);
          _state = _state.copyWith(
            artworkResults: [
              ..._state.artworkResults,
              ..._filterArtwork(page.items),
            ],
            artworkNextUrl: page.nextUrl,
            isLoadingMore: false,
          );
        case SearchResultTab.novel:
          final page = await _repository.nextNovels(nextUrl);
          _state = _state.copyWith(
            novelResults: [..._state.novelResults, ...page.items],
            novelNextUrl: page.nextUrl,
            isLoadingMore: false,
          );
        case SearchResultTab.user:
          final page = await _repository.nextUsers(nextUrl);
          _state = _state.copyWith(
            userResults: [..._state.userResults, ...page.items],
            userNextUrl: page.nextUrl,
            isLoadingMore: false,
          );
      }
    } catch (error) {
      _state = _state.copyWith(
        isLoadingMore: false,
        resultsErrorMessage: error.toString(),
      );
    }
    _notify();
  }

  Future<void> _loadResults({required bool reset}) async {
    final keyword = _state.submittedQuery.trim();
    if (keyword.isEmpty) return;

    _state = _state.copyWith(
      isResultsLoading: true,
      isLoadingMore: false,
      resultsErrorMessage: null,
      artworkResults: reset && _state.activeTab == SearchResultTab.artwork
          ? const []
          : null,
      novelResults: reset && _state.activeTab == SearchResultTab.novel
          ? const []
          : null,
      userResults: reset && _state.activeTab == SearchResultTab.user
          ? const []
          : null,
      artworkNextUrl: reset && _state.activeTab == SearchResultTab.artwork
          ? null
          : _state.artworkNextUrl,
      novelNextUrl: reset && _state.activeTab == SearchResultTab.novel
          ? null
          : _state.novelNextUrl,
      userNextUrl: reset && _state.activeTab == SearchResultTab.user
          ? null
          : _state.userNextUrl,
    );
    _notify();

    try {
      switch (_state.activeTab) {
        case SearchResultTab.artwork:
          final page = await _repository.illusts(
            word: keyword,
            sort: _state.sort,
            searchTarget: _state.filters.searchTarget,
            startDate: _state.filters.startDate,
            endDate: _state.filters.endDate,
            bookmarkNumMin: _state.filters.bookmarkMinimum,
            searchAiType: _state.filters.aiOnly ? 1 : 0,
          );
          _state = _state.copyWith(
            artworkResults: _filterArtwork(page.items),
            artworkNextUrl: page.nextUrl,
            isResultsLoading: false,
          );
        case SearchResultTab.novel:
          final page = await _repository.novels(
            word: keyword,
            sort: _state.sort,
            searchTarget: _state.filters.searchTarget,
            startDate: _state.filters.startDate,
            endDate: _state.filters.endDate,
            bookmarkNum: _state.filters.bookmarkMinimum,
          );
          _state = _state.copyWith(
            novelResults: page.items,
            novelNextUrl: page.nextUrl,
            isResultsLoading: false,
          );
        case SearchResultTab.user:
          final page = await _repository.userResults(keyword);
          _state = _state.copyWith(
            userResults: page.items,
            userNextUrl: page.nextUrl,
            isResultsLoading: false,
          );
      }
    } catch (error) {
      _state = _state.copyWith(
        isResultsLoading: false,
        resultsErrorMessage: error.toString(),
      );
    }
    _notify();
  }

  List<Artwork> _filterArtwork(List<Artwork> items) {
    final contentType = _state.filters.contentType;
    if (contentType == 'all') return items;
    return items.where((item) => item.type == contentType).toList();
  }

  String? get _activeNextUrl {
    return switch (_state.activeTab) {
      SearchResultTab.artwork => _state.artworkNextUrl,
      SearchResultTab.novel => _state.novelNextUrl,
      SearchResultTab.user => _state.userNextUrl,
    };
  }

  Future<void> _loadAutocomplete(String word, int request) async {
    try {
      final tags = await _repository.autocompleteTags(word);
      if (request != _autocompleteRequest) return;
      _state = _state.copyWith(
        autocompleteTags: tags.take(6).toList(),
        isAutocompleteLoading: false,
      );
    } catch (_) {
      if (request != _autocompleteRequest) return;
      _state = _state.copyWith(
        autocompleteTags: const [],
        isAutocompleteLoading: false,
      );
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autocompleteTimer?.cancel();
    super.dispose();
  }
}

enum SearchMode { idle, results }

enum SearchResultTab { artwork, novel, user }

@immutable
class SearchFilters {
  const SearchFilters({
    this.searchTarget = 'partial_match_for_tags',
    this.startDate,
    this.endDate,
    this.bookmarkMinimum,
    this.contentType = 'all',
    this.aiOnly = false,
  });

  final String searchTarget;
  final String? startDate;
  final String? endDate;
  final int? bookmarkMinimum;
  final String contentType;
  final bool aiOnly;

  bool get hasActiveFilters {
    return searchTarget != 'partial_match_for_tags' ||
        startDate != null ||
        endDate != null ||
        bookmarkMinimum != null ||
        contentType != 'all' ||
        aiOnly;
  }

  SearchFilters copyWith({
    String? searchTarget,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? bookmarkMinimum = _unset,
    String? contentType,
    bool? aiOnly,
  }) {
    return SearchFilters(
      searchTarget: searchTarget ?? this.searchTarget,
      startDate: startDate == _unset ? this.startDate : startDate as String?,
      endDate: endDate == _unset ? this.endDate : endDate as String?,
      bookmarkMinimum: bookmarkMinimum == _unset
          ? this.bookmarkMinimum
          : bookmarkMinimum as int?,
      contentType: contentType ?? this.contentType,
      aiOnly: aiOnly ?? this.aiOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchFilters &&
        other.searchTarget == searchTarget &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.bookmarkMinimum == bookmarkMinimum &&
        other.contentType == contentType &&
        other.aiOnly == aiOnly;
  }

  @override
  int get hashCode => Object.hash(
    searchTarget,
    startDate,
    endDate,
    bookmarkMinimum,
    contentType,
    aiOnly,
  );
}

@immutable
class SearchState {
  const SearchState({
    this.mode = SearchMode.idle,
    this.query = '',
    this.submittedQuery = '',
    this.activeTab = SearchResultTab.artwork,
    this.artworkResults = const [],
    this.novelResults = const [],
    this.userResults = const [],
    this.artworkNextUrl,
    this.novelNextUrl,
    this.userNextUrl,
    this.isResultsLoading = false,
    this.isLoadingMore = false,
    this.sort = 'date_desc',
    this.filters = const SearchFilters(),
    this.recentWords = const [],
    this.trendingTags = const [],
    this.autocompleteTags = const [],
    this.isTrendingLoading = false,
    this.isAutocompleteLoading = false,
    this.errorMessage,
    this.resultsErrorMessage,
  });

  final SearchMode mode;
  final String query;
  final String submittedQuery;
  final SearchResultTab activeTab;
  final List<Artwork> artworkResults;
  final List<Novel> novelResults;
  final List<SearchUserResult> userResults;
  final String? artworkNextUrl;
  final String? novelNextUrl;
  final String? userNextUrl;
  final bool isResultsLoading;
  final bool isLoadingMore;
  final String sort;
  final SearchFilters filters;
  final List<String> recentWords;
  final List<TrendTag> trendingTags;
  final List<PixivTag> autocompleteTags;
  final bool isTrendingLoading;
  final bool isAutocompleteLoading;
  final String? errorMessage;
  final String? resultsErrorMessage;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get hasResultsError =>
      resultsErrorMessage != null && resultsErrorMessage!.isNotEmpty;
  int get activeCount {
    return switch (activeTab) {
      SearchResultTab.artwork => artworkResults.length,
      SearchResultTab.novel => novelResults.length,
      SearchResultTab.user => userResults.length,
    };
  }

  SearchState copyWith({
    SearchMode? mode,
    String? query,
    String? submittedQuery,
    SearchResultTab? activeTab,
    List<Artwork>? artworkResults,
    List<Novel>? novelResults,
    List<SearchUserResult>? userResults,
    Object? artworkNextUrl = _unset,
    Object? novelNextUrl = _unset,
    Object? userNextUrl = _unset,
    bool? isResultsLoading,
    bool? isLoadingMore,
    String? sort,
    SearchFilters? filters,
    List<String>? recentWords,
    List<TrendTag>? trendingTags,
    List<PixivTag>? autocompleteTags,
    bool? isTrendingLoading,
    bool? isAutocompleteLoading,
    String? errorMessage,
    String? resultsErrorMessage,
  }) {
    return SearchState(
      mode: mode ?? this.mode,
      query: query ?? this.query,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      activeTab: activeTab ?? this.activeTab,
      artworkResults: artworkResults ?? this.artworkResults,
      novelResults: novelResults ?? this.novelResults,
      userResults: userResults ?? this.userResults,
      artworkNextUrl: artworkNextUrl == _unset
          ? this.artworkNextUrl
          : artworkNextUrl as String?,
      novelNextUrl: novelNextUrl == _unset
          ? this.novelNextUrl
          : novelNextUrl as String?,
      userNextUrl: userNextUrl == _unset
          ? this.userNextUrl
          : userNextUrl as String?,
      isResultsLoading: isResultsLoading ?? this.isResultsLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
      recentWords: recentWords ?? this.recentWords,
      trendingTags: trendingTags ?? this.trendingTags,
      autocompleteTags: autocompleteTags ?? this.autocompleteTags,
      isTrendingLoading: isTrendingLoading ?? this.isTrendingLoading,
      isAutocompleteLoading:
          isAutocompleteLoading ?? this.isAutocompleteLoading,
      errorMessage: errorMessage,
      resultsErrorMessage: resultsErrorMessage,
    );
  }
}

const _unset = Object();
