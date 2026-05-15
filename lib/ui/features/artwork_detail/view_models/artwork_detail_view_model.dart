import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/artwork_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../domain/models/artwork.dart';
import '../../../../domain/models/artwork_detail.dart';
import '../../../../domain/models/pixiv_creator.dart';

final artworkDetailViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<ArtworkDetailViewModel, String>((ref, illustId) {
      final viewModel = ArtworkDetailViewModel(
        illustId: illustId,
        artworkRepository: ref.watch(artworkRepositoryProvider),
        userRepository: ref.watch(userRepositoryProvider),
      );
      viewModel.load();
      return viewModel;
    });

class ArtworkDetailViewModel extends ChangeNotifier {
  ArtworkDetailViewModel({
    required String illustId,
    required ArtworkRepository artworkRepository,
    required UserRepository userRepository,
  }) : _illustId = illustId,
       _artworkRepository = artworkRepository,
       _userRepository = userRepository;

  final String _illustId;
  final ArtworkRepository _artworkRepository;
  final UserRepository _userRepository;

  ArtworkDetailState _state = const ArtworkDetailState(isLoading: true);

  ArtworkDetailState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final detail = await _artworkRepository.detailFull(_illustId);
      if (detail == null) {
        _state = const ArtworkDetailState(errorMessage: 'Artwork not found.');
      } else {
        _state = ArtworkDetailState(detail: detail);
      }
    } catch (error) {
      _state = ArtworkDetailState(errorMessage: error.toString());
    }

    notifyListeners();
  }

  Future<void> toggleBookmark() async {
    final detail = _state.detail;
    if (detail == null || _state.isBookmarking) return;

    final artwork = detail.artwork;
    final next = !artwork.isBookmarked;
    final optimistic = _withArtwork(
      detail,
      _copyArtwork(artwork, isBookmarked: next),
    );

    _state = _state.copyWith(detail: optimistic, isBookmarking: true);
    notifyListeners();

    try {
      if (next) {
        await _artworkRepository.addBookmark(illustId: artwork.id);
      } else {
        await _artworkRepository.deleteBookmark(artwork.id);
      }
      _state = _state.copyWith(isBookmarking: false, errorMessage: null);
    } catch (error) {
      _state = _state.copyWith(
        detail: detail,
        isBookmarking: false,
        errorMessage: error.toString(),
      );
    }

    notifyListeners();
  }

  Future<void> toggleFollow() async {
    final detail = _state.detail;
    if (detail == null || _state.isFollowing) return;

    final creator = detail.creator;
    final next = !creator.isFollowed;
    final optimistic = detail.copyWith(
      creator: _copyCreator(creator, isFollowed: next),
    );

    _state = _state.copyWith(detail: optimistic, isFollowing: true);
    notifyListeners();

    try {
      if (next) {
        await _userRepository.follow(userId: creator.id);
      } else {
        await _userRepository.unfollow(creator.id);
      }
      _state = _state.copyWith(isFollowing: false, errorMessage: null);
    } catch (error) {
      _state = _state.copyWith(
        detail: detail,
        isFollowing: false,
        errorMessage: error.toString(),
      );
    }

    notifyListeners();
  }

  ArtworkDetail _withArtwork(ArtworkDetail detail, Artwork artwork) {
    return detail.copyWith(artwork: artwork);
  }

  Artwork _copyArtwork(Artwork artwork, {required bool isBookmarked}) {
    return Artwork(
      id: artwork.id,
      title: artwork.title,
      artist: artwork.artist,
      bookmarks: artwork.bookmarks,
      gradient: artwork.gradient,
      imageUrl: artwork.imageUrl,
      pageCount: artwork.pageCount,
      isBookmarked: isBookmarked,
      xRestrict: artwork.xRestrict,
      isSpotlight: artwork.isSpotlight,
    );
  }

  PixivCreator _copyCreator(PixivCreator creator, {required bool isFollowed}) {
    return PixivCreator(
      id: creator.id,
      name: creator.name,
      account: creator.account,
      avatarUrl: creator.avatarUrl,
      isFollowed: isFollowed,
      profile: creator.profile,
      profilePublicity: creator.profilePublicity,
      workspace: creator.workspace,
    );
  }
}

@immutable
class ArtworkDetailState {
  const ArtworkDetailState({
    this.detail,
    this.isLoading = false,
    this.isBookmarking = false,
    this.isFollowing = false,
    this.errorMessage,
  });

  final ArtworkDetail? detail;
  final bool isLoading;
  final bool isBookmarking;
  final bool isFollowing;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  ArtworkDetailState copyWith({
    ArtworkDetail? detail,
    bool? isLoading,
    bool? isBookmarking,
    bool? isFollowing,
    String? errorMessage,
  }) {
    return ArtworkDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      isBookmarking: isBookmarking ?? this.isBookmarking,
      isFollowing: isFollowing ?? this.isFollowing,
      errorMessage: errorMessage,
    );
  }
}
