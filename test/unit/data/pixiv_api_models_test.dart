import 'package:bysiv/data/models/pixiv_account_models.dart';
import 'package:bysiv/data/models/pixiv_common_models.dart' as api;
import 'package:bysiv/data/models/pixiv_recommend_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pixiv API models', () {
    test('parse common model JSON shapes and defaults', () {
      final imageUrls = api.PixivImageUrls.fromJson({
        'square_medium': 'square.jpg',
        'medium': 'medium.jpg',
        'large': 'large.jpg',
        'original': 'original.jpg',
      });
      expect(imageUrls.best, 'original.jpg');
      expect(api.PixivImageUrls.fromJson(const {}).best, isNull);

      final user = api.PixivUser.fromJson({
        'id': 7,
        'name': 'Mika',
        'account': 'mika',
        'profile_image_urls': {'px_170x170': 'avatar.jpg'},
        'is_followed': true,
        'is_access_blocking_user': true,
      });
      expect(user.id, '7');
      expect(user.avatarUrl, 'avatar.jpg');
      expect(user.isFollowed, isTrue);

      final illust = api.PixivIllust.fromJson(_illustJson());
      expect(illust.imageUrl, 'large.jpg');
      expect(illust.pageImageUrls, ['page-original.jpg']);
      expect(illust.artistName, 'Mika');
      expect(illust.tags.single.translatedName, 'Original');

      final fallbackIllust = api.PixivIllust.fromJson({
        ..._illustJson(),
        'meta_pages': const [],
        'meta_single_page': {'original_image_url': 'single.jpg'},
      });
      expect(fallbackIllust.pageImageUrls, ['single.jpg']);

      final novel = api.PixivNovel.fromJson(_novelJson());
      expect(novel.series!.title, 'Series');
      expect(novel.imageUrls.best, 'novel.jpg');
      expect(novel.tags.single.name, 'novel-tag');

      expect(api.PixivSeries.fromJson({'series_id': 9, 'title': 'S'}).id, '9');
      expect(api.PixivComment.fromJson(_commentJson()).hasReplies, isTrue);
      expect(
        api.PixivBookmarkDetail.fromJson(_bookmarkDetailJson()).tags,
        hasLength(1),
      );
      expect(
        api.PixivUserPreview.fromJson(_userPreviewJson()).illusts,
        hasLength(1),
      );
      expect(
        api.PixivUserDetail.fromJson(_userDetailJson()).profile['webpage'],
        'site',
      );
      expect(
        api.PixivFollowDetail.fromJson({'is_followed': true}).restrict,
        'public',
      );
      expect(
        api.PixivUgoiraMetadata.fromJson(_ugoiraJson()).frames.single.delay,
        80,
      );
      expect(api.PixivTrendTag.fromJson(_trendTagJson()).illust, isNotNull);
      expect(
        api.PixivSpotlightArticle.fromJson(_spotlightJson()).pureTitle,
        'Pure',
      );
      expect(
        api.PixivNovelText.fromJson({'novel_id': 55, 'text': 'body'}).novelId,
        '55',
      );
      expect(
        PixivRecommendResponse.fromJson(_illustPage()).illusts,
        hasLength(1),
      );
      expect(PixivRecommendResponse.fromJson(const {}).illusts, isEmpty);
      expect(
        PixivProvisionalAccount.fromJson(_provisionalJson()).deviceToken,
        'device',
      );
      expect(
        PixivAccountResponse.fromJson(_accountResponseJson()).hasError,
        isTrue,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// JSON fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _illustPage() => {
  'illusts': [_illustJson()],
  'next_url': 'next',
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
    {
      'image_urls': {'original': 'page-original.jpg'},
    },
  ],
};

Map<String, dynamic> _novelJson() => {
  'id': 'novel-1',
  'title': 'Novel',
  'user': _userJson(),
  'image_urls': {'large': 'novel.jpg'},
  'tags': [
    {'tag': 'novel-tag'},
  ],
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
  'frames': [
    {'file': '000001.jpg', 'delay': 80},
  ],
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

Map<String, dynamic> _provisionalJson() => {
  'user_account': 'temp',
  'password': 'secret',
  'device_token': 'device',
};

Map<String, dynamic> _accountResponseJson() => {
  'error': true,
  'message': 'Invalid',
  'body': {'code': 'invalid'},
};
