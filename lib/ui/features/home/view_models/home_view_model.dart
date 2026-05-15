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
  final List<String> _filters = const [
    'Recommend',
    'Ranking',
    'Original',
    'Following',
  ];

  HomeState _state = const HomeState(
    filters: ['Recommend', 'Ranking', 'Original', 'Following'],
    artwork: [],
    isLoading: true,
  );

  HomeState get state => _state;

  Future<void> loadRecommended() async {
    await _load(showLoading: _state.artwork.isEmpty);
  }

  Future<void> refresh() async {
    await _load(showLoading: false);
  }

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) {
      _state = _state.copyWith(isLoading: true, errorMessage: null);
      notifyListeners();
    }

    try {
      final artwork = await _repository.recommendedArtwork();
      _state = HomeState(filters: _filters, artwork: artwork, isLoading: false);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }

    notifyListeners();
  }
}

@immutable
class HomeState {
  const HomeState({
    required this.filters,
    required this.artwork,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<String> filters;
  final List<Artwork> artwork;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  bool get isEmpty => !isLoading && artwork.isEmpty && !hasError;

  HomeState copyWith({
    List<String>? filters,
    List<Artwork>? artwork,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HomeState(
      filters: filters ?? this.filters,
      artwork: artwork ?? this.artwork,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
