import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/artwork_repository.dart';
import '../../../../data/repositories/discover_repository.dart';
import '../../../../data/repositories/discovery_repository.dart';
import '../../../../data/repositories/novel_repository.dart';
import '../../../../domain/models/artwork.dart';
import '../../../../domain/models/novel.dart';
import '../../../../domain/models/pixiv_creator.dart';
import '../../../../domain/models/spotlight_article.dart';

enum NewsFeedTab {
  recommended('Recommended'),
  following('Following');

  const NewsFeedTab(this.label);

  final String label;
}

enum NewsContentType { artworks, novels }

final newsViewModelProvider = ChangeNotifierProvider<NewsViewModel>((ref) {
  final viewModel = NewsViewModel(
    artworkRepository: ref.watch(artworkRepositoryProvider),
    discoverRepository: ref.watch(discoverRepositoryProvider),
    discoveryRepository: ref.watch(discoveryRepositoryProvider),
    novelRepository: ref.watch(novelRepositoryProvider),
  );
  viewModel.load();
  return viewModel;
});

class NewsState {
  const NewsState({
    this.feedTab = NewsFeedTab.recommended,
    this.contentType = NewsContentType.artworks,
    this.articles = const [],
    this.artworks = const [],
    this.novels = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final NewsFeedTab feedTab;
  final NewsContentType contentType;
  final List<SpotlightArticle> articles;
  final List<Artwork> artworks;
  final List<Novel> novels;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get isEmpty =>
      contentType == NewsContentType.artworks ? artworks.isEmpty : novels.isEmpty;

  NewsState copyWith({
    NewsFeedTab? feedTab,
    NewsContentType? contentType,
    List<SpotlightArticle>? articles,
    List<Artwork>? artworks,
    List<Novel>? novels,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NewsState(
      feedTab: feedTab ?? this.feedTab,
      contentType: contentType ?? this.contentType,
      articles: articles ?? this.articles,
      artworks: artworks ?? this.artworks,
      novels: novels ?? this.novels,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NewsViewModel extends ChangeNotifier {
  NewsViewModel({
    required ArtworkRepository artworkRepository,
    required DiscoverRepository discoverRepository,
    required DiscoveryRepository discoveryRepository,
    required NovelRepository novelRepository,
  }) : _artworkRepository = artworkRepository,
       _discoverRepository = discoverRepository,
       _discoveryRepository = discoveryRepository,
       _novelRepository = novelRepository;

  final ArtworkRepository _artworkRepository;
  final DiscoverRepository _discoverRepository;
  final DiscoveryRepository _discoveryRepository;
  final NovelRepository _novelRepository;

  NewsState _state = const NewsState();
  NewsState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      final articles = await _discoveryRepository.spotlightArticles();
      final artworks = await _loadArtwork(_state.feedTab);
      final novels = await _novelRepository.recommended();

      _state = _state.copyWith(
        articles: articles.items,
        artworks: artworks,
        novels: novels.items,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (_state.artworks.isEmpty && _state.novels.isEmpty) {
        _state = _state.copyWith(
          artworks: Artwork.samples,
          novels: _sampleNovels,
          isLoading: false,
          clearError: true,
        );
      } else {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      }
    }

    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> selectFeedTab(NewsFeedTab tab) async {
    if (_state.feedTab == tab && _state.artworks.isNotEmpty) return;

    _state = _state.copyWith(
      feedTab: tab,
      contentType: NewsContentType.artworks,
      isLoading: true,
      clearError: true,
    );
    notifyListeners();

    try {
      final artworks = await _loadArtwork(tab);
      _state = _state.copyWith(
        artworks: artworks,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }

    notifyListeners();
  }

  void selectContentType(NewsContentType type) {
    if (_state.contentType == type) return;
    _state = _state.copyWith(contentType: type);
    notifyListeners();
  }

  Future<List<Artwork>> _loadArtwork(NewsFeedTab tab) async {
    return switch (tab) {
      NewsFeedTab.recommended =>
        (await _artworkRepository.recommendedIllusts()).items,
      NewsFeedTab.following => _discoverRepository.followingArtwork(),
    };
  }
}

const _sampleNovels = [
  Novel(
    id: 'sample-novel-1',
    title: '星の記憶',
    author: PixivCreator(id: 'sample-author-1', name: 'Aki', account: 'aki'),
    bookmarks: 450,
    caption: '物語の始まりは、いつも静かな夜だった。',
    textLength: 12000,
    totalView: 8200,
  ),
  Novel(
    id: 'sample-novel-2',
    title: '夜明けの約束',
    author: PixivCreator(id: 'sample-author-2', name: 'Yuu', account: 'yuu'),
    bookmarks: 820,
    caption: '遠くで汽笛が聞こえる朝に、ふたりはまた出会う。',
    textLength: 18400,
    totalView: 12600,
  ),
];
