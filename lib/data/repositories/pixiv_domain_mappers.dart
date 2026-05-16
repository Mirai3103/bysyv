import 'package:flutter/material.dart';

import '../../domain/models/artwork.dart';
import '../../domain/models/artwork_detail.dart';
import '../../domain/models/bookmark_detail.dart';
import '../../domain/models/feed_page.dart';
import '../../domain/models/novel.dart';
import '../../domain/models/pixiv_comment.dart' as domain;
import '../../domain/models/pixiv_creator.dart';
import '../../domain/models/pixiv_tag.dart' as domain;
import '../../domain/models/spotlight_article.dart';
import '../../domain/models/trend_tag.dart';
import '../models/pixiv_common_models.dart' as api;

FeedPage<TDomain> mapPage<TApi, TDomain>(
  api.PixivPage<TApi> page,
  TDomain Function(TApi item) mapper,
) {
  return FeedPage(
    items: page.items.map(mapper).toList(),
    nextUrl: page.nextUrl,
  );
}

Artwork mapIllust(api.PixivIllust illust) {
  return Artwork(
    id: illust.id,
    title: illust.title,
    artist: illust.artistName,
    bookmarks: illust.totalBookmarks,
    imageUrl: illust.imageUrl,
    pageCount: illust.pageCount,
    isBookmarked: illust.isBookmarked,
    xRestrict: illust.xRestrict,
    type: illust.type,
    aiType: illust.illustAiType,
    gradient: const [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
  );
}

ArtworkDetail mapArtworkDetail({
  required api.PixivIllust illust,
  List<domain.PixivComment> comments = const [],
  List<Artwork> related = const [],
}) {
  final fallbackUrl = illust.originalImageUrl ?? illust.imageUrl;
  final pageUrls = illust.pageImageUrls;
  final urls = pageUrls.isEmpty && fallbackUrl != null
      ? [fallbackUrl]
      : pageUrls;

  return ArtworkDetail(
    artwork: mapIllust(illust),
    creator: mapCreator(illust.user),
    tags: illust.tags.map(mapTag).toList(),
    pages: [
      for (final url in urls)
        ArtworkImagePage(
          imageUrl: url,
          width: illust.width,
          height: illust.height,
        ),
    ],
    related: related,
    comments: comments,
    caption: _stripHtml(illust.caption),
    createDate: illust.createDate,
    totalView: illust.totalView,
    totalBookmarks: illust.totalBookmarks,
    totalComments: illust.totalComments,
  );
}

Novel mapNovel(api.PixivNovel novel) {
  return Novel(
    id: novel.id,
    title: novel.title,
    author: mapCreator(novel.user),
    bookmarks: novel.totalBookmarks,
    caption: novel.caption,
    imageUrl: novel.imageUrls.best,
    pageCount: novel.pageCount,
    textLength: novel.textLength,
    totalView: novel.totalView,
    totalComments: novel.totalComments,
    isBookmarked: novel.isBookmarked,
    tags: novel.tags.map(mapTag).toList(),
  );
}

PixivCreator mapCreator(api.PixivUser user) {
  return PixivCreator(
    id: user.id,
    name: user.name,
    account: user.account,
    avatarUrl: user.avatarUrl,
    isFollowed: user.isFollowed,
  );
}

PixivCreator mapCreatorDetail(api.PixivUserDetail detail) {
  return PixivCreator(
    id: detail.user.id,
    name: detail.user.name,
    account: detail.user.account,
    avatarUrl: detail.user.avatarUrl,
    isFollowed: detail.user.isFollowed,
    profile: detail.profile,
    profilePublicity: detail.profilePublicity,
    workspace: detail.workspace,
  );
}

domain.PixivTag mapTag(api.PixivTag tag) {
  return domain.PixivTag(name: tag.name, translatedName: tag.translatedName);
}

domain.PixivComment mapComment(api.PixivComment comment) {
  return domain.PixivComment(
    id: comment.id,
    body: comment.comment,
    user: mapCreator(comment.user),
    date: comment.date,
    hasReplies: comment.hasReplies,
  );
}

BookmarkDetail mapBookmarkDetail(api.PixivBookmarkDetail detail) {
  return BookmarkDetail(
    isBookmarked: detail.isBookmarked,
    restrict: detail.restrict,
    tags: detail.tags.map(mapBookmarkTag).toList(),
  );
}

BookmarkTag mapBookmarkTag(api.PixivBookmarkTag tag) {
  return BookmarkTag(
    name: tag.name,
    count: tag.count,
    isRegistered: tag.isRegistered,
  );
}

TrendTag mapTrendTag(api.PixivTrendTag tag) {
  return TrendTag(
    tag: tag.tag,
    translatedName: tag.translatedName,
    artwork: tag.illust == null ? null : mapIllust(tag.illust!),
  );
}

SpotlightArticle mapSpotlightArticle(api.PixivSpotlightArticle article) {
  return SpotlightArticle(
    id: article.id,
    title: article.title,
    pureTitle: article.pureTitle,
    thumbnailUrl: article.thumbnail,
    articleUrl: article.articleUrl,
    publishDate: article.publishDate,
  );
}

String? _stripHtml(String? input) {
  if (input == null || input.trim().isEmpty) return null;
  return input
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}
