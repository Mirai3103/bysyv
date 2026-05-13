import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/discover_repository.dart';
import '../../../../domain/models/artwork.dart';

final homeViewModelProvider = Provider<HomeViewModel>((ref) {
  return HomeViewModel(repository: ref.watch(discoverRepositoryProvider));
});

class HomeViewModel {
  const HomeViewModel({required DiscoverRepository repository})
    : _repository = repository;

  final DiscoverRepository _repository;

  HomeState build() {
    return HomeState(
      filters: const ['For you', 'Ranking', 'Original', 'Following'],
      artwork: _repository.featuredArtwork(),
    );
  }
}

class HomeState {
  const HomeState({required this.filters, required this.artwork});

  final List<String> filters;
  final List<Artwork> artwork;
}
