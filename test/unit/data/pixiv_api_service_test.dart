import 'package:dio/dio.dart';
import 'package:bysiv/data/services/pixiv_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dio_helpers.dart';

void main() {
  group('PixivApiService', () {
    test('maps GET and POST wrappers without network access', () async {
      final seen = <RequestOptions>[];
      final dio = dioWithResponses(seen, [
        _illustPage(),
        _illustPage(),
        _illustPage(),
        _illustPage(),
        {'illust': _illustJson()},
        _illustPage(),
        {'ugoira_metadata': _ugoiraJson()},
        {'is_bookmarked': true},
        {'is_bookmarked': false},
        {'is_bookmarked': false},
        {'bookmark_detail': _bookmarkDetailJson()},
        _illustPage(),
        {'illust_series': [_seriesJson()]},
        {'series': [_seriesJson()], 'next_url': 'series-next'},
        {},
        {},
        _commentPage(),
        _commentPage(),
        {'comment': _commentJson()},
        _novelPage(),
        _novelPage(),
        {'novel': _novelJson()},
        {'novel_text': {'novel_id': 'novel-1', 'text': 'text'}},
        {'html': '<body></body>'},
        _novelPage(),
        {'novel_series': [_seriesJson()], 'next_url': 'novel-series-next'},
        {},
        {},
        {},
        {},
        _commentPage(),
        _commentPage(),
        {'comment': _commentJson()},
        _userDetailJson(),
        _userPreviewPage(),
        _illustPage(),
        _novelPage(),
        _illustPage(),
        _novelPage(),
        {'bookmark_tags': [_bookmarkTagJson()], 'next_url': 'tag-next'},
        _userPreviewPage(),
        _userPreviewPage(),
        {'follow_detail': {'is_followed': true, 'restrict': 'private'}},
        {'is_followed': true},
        {'is_followed': false},
        {'show_ai': false},
        {},
        {'is_restricted_mode_enabled': true},
        {},
        _illustPage(),
        _novelPage(),
        _userPreviewPage(),
        {'tags': [_tagJson()]},
        _illustPage(),
        {'trend_tags': [_trendTagJson()]},
        {'trend_tags': [_trendTagJson()]},
        {'spotlight_articles': [_spotlightJson()], 'next_url': 'spot-next'},
        {'custom': true},
        _illustPage(),
        _novelPage(),
        _userPreviewPage(),
      ]);
      final service = PixivApiService(dio: dio);

      expect((await service.getRecommendedIllusts()).illusts, hasLength(1));
      expect((await service.getRecommendedManga()).items, hasLength(1));
      expect(
        (await service.getIllustRanking(mode: 'day', date: '2026-05-16'))
            .nextUrl,
        'next',
      );
      expect(await service.getWalkthroughIllusts(), hasLength(1));
      expect((await service.getIllustDetail('illust-1'))!.title, 'Blue hour');
      expect((await service.getRelatedIllusts('illust-1')).items, hasLength(1));
      expect(
        (await service.getUgoiraMetadata('illust-1'))!.zipUrl,
        'ugoira.zip',
      );
      expect(
        await service.addIllustBookmark(illustId: 'illust-1', tags: ['miku']),
        isTrue,
      );
      expect(await service.deleteIllustBookmark('illust-1'), isFalse);
      expect(await service.deleteIllustBookmarkByGet('illust-1'), isFalse);
      expect(
        (await service.getIllustBookmarkDetail('illust-1'))!.tags,
        hasLength(1),
      );
      expect((await service.getFollowIllusts()).items, hasLength(1));
      expect(await service.getIllustSeriesForIllust('illust-1'), hasLength(1));
      expect((await service.getMangaWatchlist()).nextUrl, 'series-next');
      await service.addMangaWatchlist('series-1');
      await service.deleteMangaWatchlist('series-1');
      expect((await service.getIllustComments('illust-1')).items, hasLength(1));
      expect(
        (await service.getIllustCommentReplies('comment-1')).items,
        hasLength(1),
      );
      expect(
        (await service.addIllustComment(
          illustId: 'illust-1',
          comment: 'Nice',
        ))!.id,
        'comment-1',
      );
      expect((await service.getRecommendedNovels()).items, hasLength(1));
      expect(
        (await service.getNovelRanking(mode: 'day')).items,
        hasLength(1),
      );
      expect((await service.getNovelDetail('novel-1'))!.title, 'Novel');
      expect((await service.getNovelText('novel-1'))!.text, 'text');
      expect(
        (await service.getNovelWebView('novel-1')).data,
        containsPair('html', '<body></body>'),
      );
      expect((await service.getFollowNovels()).items, hasLength(1));
      expect(
        (await service.getNovelWatchlist()).nextUrl,
        'novel-series-next',
      );
      await service.addNovelWatchlist('series-1');
      await service.deleteNovelWatchlist('series-1');
      await service.addNovelBookmark(novelId: 'novel-1');
      await service.deleteNovelBookmark('novel-1');
      expect((await service.getNovelComments('novel-1')).items, hasLength(1));
      expect(
        (await service.getNovelCommentReplies('comment-1')).items,
        hasLength(1),
      );
      expect(
        (await service.addNovelComment(novelId: 'novel-1', comment: 'Nice'))!
            .comment,
        'Hello',
      );
      expect((await service.getUserDetail('user-1'))!.user.name, 'Mika');
      expect((await service.getRecommendedUsers()).items, hasLength(1));
      expect(
        (await service.getUserIllusts(userId: 'user-1', offset: 10)).items,
        hasLength(1),
      );
      expect((await service.getUserNovels('user-1')).items, hasLength(1));
      expect(
        (await service.getUserIllustBookmarks(
          userId: 'user-1',
          tag: 'miku',
        )).items,
        hasLength(1),
      );
      expect(
        (await service.getUserNovelBookmarks(userId: 'user-1')).items,
        hasLength(1),
      );
      expect(
        (await service.getUserIllustBookmarkTags(userId: 'user-1')).items,
        hasLength(1),
      );
      expect(
        (await service.getUserFollowing(userId: 'user-1')).items,
        hasLength(1),
      );
      expect(
        (await service.getUserFollowers(userId: 'user-1')).items,
        hasLength(1),
      );
      expect(
        (await service.getUserFollowDetail('user-1'))!.restrict,
        'private',
      );
      expect(await service.addUserFollow(userId: 'user-1'), isTrue);
      expect(await service.deleteUserFollow('user-1'), isFalse);
      expect(await service.getShowAiSetting(), isFalse);
      await service.editShowAiSetting(true);
      expect(await service.getRestrictedModeSetting(), isTrue);
      await service.editRestrictedModeSetting(false);
      expect(
        (await service.searchIllusts(word: 'miku', bookmarkNumMax: 100)).items,
        hasLength(1),
      );
      expect(
        (await service.searchNovels(word: 'miku', bookmarkNum: 100)).items,
        hasLength(1),
      );
      expect((await service.searchUsers('miku')).items, hasLength(1));
      expect(await service.autocompleteTags('miku'), hasLength(1));
      expect(
        (await service.getPopularIllustPreview(word: 'miku')).items,
        hasLength(1),
      );
      expect(await service.getTrendingIllustTags(), hasLength(1));
      expect(await service.getTrendingNovelTags(), hasLength(1));
      expect((await service.getSpotlightArticles()).items, hasLength(1));
      expect(
        await service.getNext('https://example.com/next'),
        containsPair('custom', true),
      );
      expect(
        (await service.getNextIllustPage('next-illust')).items,
        hasLength(1),
      );
      expect(
        (await service.getNextNovelPage('next-novel')).items,
        hasLength(1),
      );
      expect(
        (await service.getNextUserPreviewPage('next-user')).items,
        hasLength(1),
      );

      expect(seen.first.path, '/v1/illust/recommended');
      expect(seen[2].queryParameters['date'], '2026-05-16');
      expect(seen[7].data['tags[]'], 'miku');
      expect(
        seen
            .singleWhere((o) => o.path == '/v1/user/illusts')
            .queryParameters['offset'],
        10,
      );
      expect(
        seen
            .singleWhere((o) => o.path == '/v1/search/illust')
            .queryParameters['bookmark_num_max'],
        100,
      );
    });

    test(
      'returns empty collections and null detail for unexpected payloads',
      () async {
        final service = PixivApiService(
          dio: dioWithResponses([], [
            const {},
            const {},
            const {},
            const {},
            const {},
            const {},
            const {},
            const {},
          ]),
        );

        expect(await service.getIllustDetail('missing'), isNull);
        expect(await service.getUgoiraMetadata('missing'), isNull);
        expect(await service.getIllustBookmarkDetail('missing'), isNull);
        expect(await service.getIllustSeriesForIllust('missing'), isEmpty);
        expect((await service.getMangaWatchlist()).items, isEmpty);
        expect(await service.getNovelDetail('missing'), isNull);
        expect(await service.getUserFollowDetail('missing'), isNull);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// JSON fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _illustPage() => {
  'illusts': [_illustJson()],
  'next_url': 'next',
};

Map<String, dynamic> _novelPage() => {
  'novels': [_novelJson()],
  'next_url': 'next',
};

Map<String, dynamic> _commentPage() => {
  'comments': [_commentJson()],
  'next_url': 'comments-next',
};

Map<String, dynamic> _userPreviewPage() => {
  'user_previews': [_userPreviewJson()],
  'next_url': 'users-next',
};

Map<String, dynamic> _illustJson() => {
  'id': 'illust-1',
  'title': 'Blue hour',
  'type': 'illust',
  'user': _userJson(),
  'total_view': 1200,
  'total_bookmarks': 300,
  'image_urls': {'large': 'large.jpg'},
  'tags': [_tagJson()],
  'caption': '<p>Line<br>&amp; title</p>',
  'create_date': '2026-05-16T00:00:00+09:00',
  'page_count': 2,
  'width': 800,
  'height': 1200,
  'restrict': 0,
  'x_restrict': 1,
  'sanity_level': 4,
  'is_bookmarked': true,
  'visible': true,
  'is_muted': false,
  'illust_ai_type': 2,
  'total_comments': 3,
  'meta_single_page': {'original_image_url': 'single.jpg'},
  'meta_pages': [
    {'image_urls': {'original': 'page-original.jpg'}},
  ],
};

Map<String, dynamic> _novelJson() => {
  'id': 'novel-1',
  'title': 'Novel',
  'user': _userJson(),
  'image_urls': {'large': 'novel.jpg'},
  'tags': [{'tag': 'novel-tag'}],
  'caption': 'Caption',
  'create_date': '2026-05-16T00:00:00+09:00',
  'page_count': 10,
  'text_length': 12000,
  'total_bookmarks': 55,
  'total_view': 999,
  'total_comments': 2,
  'restrict': 0,
  'x_restrict': 0,
  'is_original': true,
  'is_bookmarked': true,
  'visible': true,
  'is_muted': false,
  'is_mypixiv_only': false,
  'is_x_restricted': false,
  'novel_ai_type': 1,
  'series': _seriesJson(),
};

Map<String, dynamic> _userJson() => {
  'id': 'user-1',
  'name': 'Mika',
  'account': 'mika',
  'profile_image_urls': {'medium': 'avatar.jpg'},
  'is_followed': true,
};

Map<String, dynamic> _tagJson() => {
  'name': 'original',
  'translated_name': 'Original',
  'added_by_uploaded_user': true,
};

Map<String, dynamic> _commentJson() => {
  'id': 'comment-1',
  'comment': 'Hello',
  'user': _userJson(),
  'date': '2026-05-16T00:00:00+09:00',
  'has_replies': true,
};

Map<String, dynamic> _bookmarkDetailJson() => {
  'is_bookmarked': true,
  'restrict': 'private',
  'tags': [_bookmarkTagJson()],
};

Map<String, dynamic> _bookmarkTagJson() => {
  'name': 'favorite',
  'count': 4,
  'is_registered': true,
};

Map<String, dynamic> _userPreviewJson() => {
  'user': _userJson(),
  'illusts': [_illustJson()],
};

Map<String, dynamic> _userDetailJson() => {
  'user': _userJson(),
  'profile': {'webpage': 'site'},
  'profile_publicity': {'gender': 'public'},
  'workspace': {'chair': 'good'},
};

Map<String, dynamic> _seriesJson() => {'id': 'series-1', 'title': 'Series'};

Map<String, dynamic> _ugoiraJson() => {
  'zip_urls': {'medium': 'ugoira.zip'},
  'frames': [{'file': '000001.jpg', 'delay': 80}],
};

Map<String, dynamic> _trendTagJson() => {
  'tag': 'miku',
  'translated_name': 'Miku',
  'illust': _illustJson(),
};

Map<String, dynamic> _spotlightJson() => {
  'id': 'spot-1',
  'title': 'Spotlight',
  'pure_title': 'Pure',
  'thumbnail': 'thumb.jpg',
  'article_url': 'https://example.com/article',
  'publish_date': '2026-05-16',
};
