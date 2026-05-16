import 'package:bysiv/data/models/pixiv_common_models.dart' as api;
import 'package:bysiv/data/repositories/pixiv_domain_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pixiv domain mappers', () {
    test('convert API DTOs to domain models', () {
      final illust = api.PixivIllust.fromJson(_illustJson());
      final novel = api.PixivNovel.fromJson(_novelJson());
      final comment = api.PixivComment.fromJson(_commentJson());

      final artwork = mapIllust(illust);
      expect(artwork.id, 'illust-1');
      expect(artwork.artist, 'Mika');
      expect(artwork.isBookmarked, isTrue);

      final detail = mapArtworkDetail(
        illust: illust,
        comments: [mapComment(comment)],
        related: [artwork],
      );
      expect(detail.creator.name, 'Mika');
      expect(detail.pages.single.imageUrl, 'page-original.jpg');
      expect(detail.caption, 'Line\n& title');
      expect(detail.totalComments, 3);

      expect(mapNovel(novel).author.account, 'mika');
      expect(
        mapCreatorDetail(
          api.PixivUserDetail.fromJson(_userDetailJson()),
        ).profile['webpage'],
        'site',
      );
      expect(
        mapBookmarkDetail(
          api.PixivBookmarkDetail.fromJson(_bookmarkDetailJson()),
        ).tags.single.count,
        4,
      );
      expect(
        mapTrendTag(api.PixivTrendTag.fromJson(_trendTagJson())).artwork,
        isNotNull,
      );
      expect(
        mapSpotlightArticle(
          api.PixivSpotlightArticle.fromJson(_spotlightJson()),
        ).articleUrl,
        'https://example.com/article',
      );

      final page = mapPage(
        api.PixivPage(items: [illust], nextUrl: 'next'),
        mapIllust,
      );
      expect(page.items.single.title, 'Blue hour');
      expect(page.nextUrl, 'next');
    });
  });
}

// ---------------------------------------------------------------------------
// JSON fixtures
// ---------------------------------------------------------------------------

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
  'series': {'id': 'series-1', 'title': 'Series'},
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
  'tags': [
    {'name': 'favorite', 'count': 4, 'is_registered': true},
  ],
};

Map<String, dynamic> _userDetailJson() => {
  'user': _userJson(),
  'profile': {'webpage': 'site'},
  'profile_publicity': {'gender': 'public'},
  'workspace': {'chair': 'good'},
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
