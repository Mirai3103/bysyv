import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/discover_repository.dart';
import '../../../../domain/models/artwork.dart';

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  final viewModel = HomeViewModel(
    repository: ref.watch(discoverRepositoryProvider),
  );
  viewModel.loadRecommended();
  return viewModel;
});

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required DiscoverRepository repository})
    : _repository = repository;

  final DiscoverRepository _repository;
  final List<HomeFilter> _filters = const [
    HomeFilter.recommend,
    HomeFilter.ranking,
    HomeFilter.original,
    HomeFilter.following,
  ];

  HomeState _state = const HomeState(
    filters: [
      HomeFilter.recommend,
      HomeFilter.ranking,
      HomeFilter.original,
      HomeFilter.following,
    ],
    activeFilter: HomeFilter.recommend,
    artwork: [],
    isLoading: true,
  );

  HomeState get state => _state;

  Future<void> loadRecommended() async {
    await _load(
      filter: HomeFilter.recommend,
      showLoading: _state.artwork.isEmpty,
    );
  }

  Future<void> refresh() async {
    await _load(filter: _state.activeFilter, showLoading: false);
  }

  Future<void> selectFilter(HomeFilter filter) async {
    if (filter == _state.activeFilter && _state.artwork.isNotEmpty) {
      return;
    }

    await _load(filter: filter, showLoading: true);
  }

  Future<void> _load({
    required HomeFilter filter,
    required bool showLoading,
  }) async {
    if (showLoading) {
      _state = _state.copyWith(
        activeFilter: filter,
        isLoading: true,
        errorMessage: null,
      );
      notifyListeners();
    }

    try {
      final artwork = await _loadArtwork(filter);
      _state = HomeState(
        filters: _filters,
        activeFilter: filter,
        artwork: artwork,
        isLoading: false,
      );
    } catch (error) {
      _state = _state.copyWith(
        activeFilter: filter,
        isLoading: false,
        errorMessage: error.toString(),
      );
    }

    notifyListeners();
  }

  Future<List<Artwork>> _loadArtwork(HomeFilter filter) {
    return switch (filter) {
      HomeFilter.recommend => _repository.recommendedArtwork(),
      HomeFilter.ranking => _repository.rankingArtwork(),
      HomeFilter.original => _repository.originalArtwork(),
      HomeFilter.following => _repository.followingArtwork(),
    };
  }
}

enum HomeFilter {
  recommend('Recommend'),
  ranking('Ranking'),
  original('Original'),
  following('Following');

  const HomeFilter(this.label);

  final String label;
}

@immutable
class HomeState {
  const HomeState({
    required this.filters,
    required this.activeFilter,
    required this.artwork,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<HomeFilter> filters;
  final HomeFilter activeFilter;
  final List<Artwork> artwork;
  final bool isLoading;
  final String? errorMessage;

  int get activeFilterIndex =>
      filters.indexOf(activeFilter).clamp(0, filters.length - 1);

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isEmpty => !isLoading && artwork.isEmpty && !hasError;

  HomeState copyWith({
    List<HomeFilter>? filters,
    HomeFilter? activeFilter,
    List<Artwork>? artwork,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      filters: filters ?? this.filters,
      activeFilter: activeFilter ?? this.activeFilter,
      artwork: artwork ?? this.artwork,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
