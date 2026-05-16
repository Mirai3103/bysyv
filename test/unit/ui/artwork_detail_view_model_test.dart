import 'package:bysiv/data/repositories/artwork_repository.dart';
import 'package:bysiv/data/repositories/user_repository.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/domain/models/artwork_detail.dart';
import 'package:bysiv/domain/models/pixiv_creator.dart';
import 'package:bysiv/domain/models/pixiv_tag.dart';
import 'package:bysiv/ui/features/artwork_detail/view_models/artwork_detail_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArtworkDetailViewModel', () {
    test('loads detail successfully', () async {
      final vm = _makeVm(artwork: _artwork());
      await vm.load();

      expect(vm.state.isLoading, isFalse);
      expect(vm.state.detail, isNotNull);
      expect(vm.state.hasError, isFalse);
    });

    test('sets errorMessage when artwork not found', () async {
      final vm = _makeVm(artwork: null);
      await vm.load();

      expect(vm.state.hasError, isTrue);
      expect(vm.state.errorMessage, contains('not found'));
    });

    test('sets errorMessage when repository throws', () async {
      final vm = _makeVm(throws: true);
      await vm.load();

      expect(vm.state.hasError, isTrue);
      expect(vm.state.errorMessage, contains('boom'));
    });

    test('toggleBookmark optimistically updates and confirms', () async {
      final vm = _makeVm(artwork: _artwork(isBookmarked: false));
      await vm.load();

      expect(vm.state.detail!.artwork.isBookmarked, isFalse);
      await vm.toggleBookmark();
      expect(vm.state.detail!.artwork.isBookmarked, isTrue);
      expect(vm.state.isBookmarking, isFalse);
    });

    test('toggleBookmark removes bookmark when already bookmarked', () async {
      final vm = _makeVm(artwork: _artwork(isBookmarked: true));
      await vm.load();

      await vm.toggleBookmark();
      expect(vm.state.detail!.artwork.isBookmarked, isFalse);
    });

    test('toggleBookmark is no-op when detail is null', () async {
      final vm = _makeVm(artwork: null);
      await vm.load();

      var notified = 0;
      vm.addListener(() => notified++);
      await vm.toggleBookmark();
      expect(notified, 0);
    });

    test('toggleFollow optimistically updates and confirms', () async {
      final vm = _makeVm(artwork: _artwork());
      await vm.load();

      final wasFollowed = vm.state.detail!.creator.isFollowed;
      await vm.toggleFollow();
      expect(vm.state.detail!.creator.isFollowed, !wasFollowed);
      expect(vm.state.isFollowing, isFalse);
    });

    test('toggleFollow is no-op when detail is null', () async {
      final vm = _makeVm(artwork: null);
      await vm.load();

      var notified = 0;
      vm.addListener(() => notified++);
      await vm.toggleFollow();
      expect(notified, 0);
    });
  });
}

ArtworkDetailViewModel _makeVm({Artwork? artwork, bool throws = false}) {
  return ArtworkDetailViewModel(
    illustId: 'illust-1',
    artworkRepository: _FakeArtworkRepo(artwork: artwork, throws: throws),
    userRepository: _FakeUserRepo(),
  );
}

Artwork _artwork({bool isBookmarked = true}) => Artwork(
  id: 'illust-1',
  title: 'Test',
  artist: 'Mika',
  bookmarks: 100,
  gradient: const [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
  isBookmarked: isBookmarked,
);

ArtworkDetail _detail(Artwork artwork) => ArtworkDetail(
  artwork: artwork,
  creator: const PixivCreator(
    id: 'user-1',
    name: 'Mika',
    account: 'mika',
    isFollowed: false,
  ),
  tags: const [PixivTag(name: 'original')],
  pages: const [
    ArtworkImagePage(imageUrl: 'https://example.com/1.jpg', width: 800, height: 1200),
  ],
  related: const [],
  comments: const [],
  caption: '',
  createDate: '2026-05-16T00:00:00+09:00',
  totalView: 100,
  totalBookmarks: 100,
  totalComments: 0,
);

class _FakeArtworkRepo extends ArtworkRepository {
  _FakeArtworkRepo({this.artwork, this.throws = false})
      : super(apiService: PixivApiService(dio: Dio()));

  final Artwork? artwork;
  final bool throws;

  @override
  Future<ArtworkDetail?> detailFull(String illustId) async {
    if (throws) throw Exception('boom');
    if (artwork == null) return null;
    return _detail(artwork!);
  }

  @override
  Future<bool> addBookmark({
    required String illustId,
    String restrict = PixivApiService.publicRestrict,
    List<String> tags = const [],
  }) async => true;

  @override
  Future<bool> deleteBookmark(String illustId) async => true;
}

class _FakeUserRepo extends UserRepository {
  _FakeUserRepo() : super(apiService: PixivApiService(dio: Dio()));

  @override
  Future<bool> follow({
    required String userId,
    String restrict = PixivApiService.publicRestrict,
  }) async => true;

  @override
  Future<bool> unfollow(String userId) async => true;
}
