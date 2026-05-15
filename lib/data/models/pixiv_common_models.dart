typedef JsonMap = Map<String, dynamic>;

class PixivPage<T> {
  const PixivPage({required this.items, this.nextUrl});

  final List<T> items;
  final String? nextUrl;
}

class PixivImageUrls {
  const PixivImageUrls({
    this.squareMedium,
    this.medium,
    this.large,
    this.original,
  });

  final String? squareMedium;
  final String? medium;
  final String? large;
  final String? original;

  factory PixivImageUrls.fromJson(JsonMap json) {
    return PixivImageUrls(
      squareMedium: json['square_medium'] as String?,
      medium: json['medium'] as String?,
      large: json['large'] as String?,
      original: json['original'] as String?,
    );
  }

  String? get best => original ?? large ?? medium ?? squareMedium;
}

class PixivIllustPage {
  const PixivIllustPage({required this.imageUrls});

  final PixivImageUrls imageUrls;

  factory PixivIllustPage.fromJson(JsonMap json) {
    return PixivIllustPage(
      imageUrls: PixivImageUrls.fromJson(
        json['image_urls'] as JsonMap? ?? const {},
      ),
    );
  }
}

class PixivTag {
  const PixivTag({
    required this.name,
    this.translatedName,
    this.addedByUploadedUser,
  });

  final String name;
  final String? translatedName;
  final bool? addedByUploadedUser;

  factory PixivTag.fromJson(JsonMap json) {
    return PixivTag(
      name: json['name'] as String? ?? json['tag'] as String? ?? '',
      translatedName: json['translated_name'] as String?,
      addedByUploadedUser: json['added_by_uploaded_user'] as bool?,
    );
  }
}

class PixivUser {
  const PixivUser({
    required this.id,
    required this.name,
    required this.account,
    this.avatarUrl,
    this.isFollowed = false,
    this.isAccessBlockingUser = false,
  });

  final String id;
  final String name;
  final String account;
  final String? avatarUrl;
  final bool isFollowed;
  final bool isAccessBlockingUser;

  factory PixivUser.fromJson(JsonMap json) {
    final imageUrls = json['profile_image_urls'] as JsonMap? ?? const {};

    return PixivUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      account: json['account'] as String? ?? '',
      avatarUrl:
          imageUrls['medium'] as String? ??
          imageUrls['px_170x170'] as String? ??
          imageUrls['px_50x50'] as String?,
      isFollowed: json['is_followed'] as bool? ?? false,
      isAccessBlockingUser: json['is_access_blocking_user'] as bool? ?? false,
    );
  }
}

class PixivIllust {
  const PixivIllust({
    required this.id,
    required this.title,
    required this.type,
    required this.user,
    required this.totalView,
    required this.totalBookmarks,
    required this.imageUrls,
    required this.tags,
    this.caption,
    this.createDate,
    this.pageCount = 1,
    this.width = 0,
    this.height = 0,
    this.restrict = 0,
    this.xRestrict = 0,
    this.sanityLevel = 0,
    this.isBookmarked = false,
    this.visible = true,
    this.isMuted = false,
    this.illustAiType = 0,
    this.totalComments = 0,
    this.originalImageUrl,
    this.metaPages = const [],
  });

  final String id;
  final String title;
  final String type;
  final PixivUser user;
  final int totalView;
  final int totalBookmarks;
  final PixivImageUrls imageUrls;
  final List<PixivTag> tags;
  final String? caption;
  final String? createDate;
  final int pageCount;
  final int width;
  final int height;
  final int restrict;
  final int xRestrict;
  final int sanityLevel;
  final bool isBookmarked;
  final bool visible;
  final bool isMuted;
  final int illustAiType;
  final int totalComments;
  final String? originalImageUrl;
  final List<PixivIllustPage> metaPages;

  factory PixivIllust.fromJson(JsonMap json) {
    final metaSinglePage = json['meta_single_page'] as JsonMap? ?? const {};
    final metaPages = json['meta_pages'];
    final tags = json['tags'];

    return PixivIllust(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'illust',
      user: PixivUser.fromJson(json['user'] as JsonMap? ?? const {}),
      totalView: json['total_view'] as int? ?? 0,
      totalBookmarks: json['total_bookmarks'] as int? ?? 0,
      imageUrls: PixivImageUrls.fromJson(
        json['image_urls'] as JsonMap? ?? const {},
      ),
      tags: tags is List
          ? tags.whereType<JsonMap>().map(PixivTag.fromJson).toList()
          : const [],
      caption: json['caption'] as String?,
      createDate: json['create_date'] as String?,
      pageCount: json['page_count'] as int? ?? 1,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      restrict: json['restrict'] as int? ?? 0,
      xRestrict: json['x_restrict'] as int? ?? 0,
      sanityLevel: json['sanity_level'] as int? ?? 0,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      isMuted: json['is_muted'] as bool? ?? false,
      illustAiType: json['illust_ai_type'] as int? ?? 0,
      totalComments: json['total_comments'] as int? ?? 0,
      originalImageUrl: metaSinglePage['original_image_url'] as String?,
      metaPages: metaPages is List
          ? metaPages
                .whereType<JsonMap>()
                .map(PixivIllustPage.fromJson)
                .toList()
          : const [],
    );
  }

  String? get imageUrl => imageUrls.best;
  List<String> get pageImageUrls {
    final pages = metaPages
        .map((page) => page.imageUrls.best)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    if (pages.isNotEmpty) return pages;

    final single = originalImageUrl ?? imageUrls.best;
    return single == null || single.isEmpty ? const [] : [single];
  }

  String get artistName => user.name;
}

class PixivNovel {
  const PixivNovel({
    required this.id,
    required this.title,
    required this.user,
    required this.imageUrls,
    required this.tags,
    this.caption = '',
    this.createDate,
    this.pageCount = 0,
    this.textLength = 0,
    this.totalBookmarks = 0,
    this.totalView = 0,
    this.totalComments = 0,
    this.restrict = 0,
    this.xRestrict = 0,
    this.isOriginal = false,
    this.isBookmarked = false,
    this.visible = true,
    this.isMuted = false,
    this.isMypixivOnly = false,
    this.isXRestricted = false,
    this.novelAiType = 0,
    this.series,
  });

  final String id;
  final String title;
  final PixivUser user;
  final PixivImageUrls imageUrls;
  final List<PixivTag> tags;
  final String caption;
  final String? createDate;
  final int pageCount;
  final int textLength;
  final int totalBookmarks;
  final int totalView;
  final int totalComments;
  final int restrict;
  final int xRestrict;
  final bool isOriginal;
  final bool isBookmarked;
  final bool visible;
  final bool isMuted;
  final bool isMypixivOnly;
  final bool isXRestricted;
  final int novelAiType;
  final PixivSeries? series;

  factory PixivNovel.fromJson(JsonMap json) {
    final tags = json['tags'];
    final series = json['series'];

    return PixivNovel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      user: PixivUser.fromJson(json['user'] as JsonMap? ?? const {}),
      imageUrls: PixivImageUrls.fromJson(
        json['image_urls'] as JsonMap? ?? const {},
      ),
      tags: tags is List
          ? tags.whereType<JsonMap>().map(PixivTag.fromJson).toList()
          : const [],
      caption: json['caption'] as String? ?? '',
      createDate: json['create_date'] as String?,
      pageCount: json['page_count'] as int? ?? 0,
      textLength: json['text_length'] as int? ?? 0,
      totalBookmarks: json['total_bookmarks'] as int? ?? 0,
      totalView: json['total_view'] as int? ?? 0,
      totalComments: json['total_comments'] as int? ?? 0,
      restrict: json['restrict'] as int? ?? 0,
      xRestrict: json['x_restrict'] as int? ?? 0,
      isOriginal: json['is_original'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      visible: json['visible'] as bool? ?? true,
      isMuted: json['is_muted'] as bool? ?? false,
      isMypixivOnly: json['is_mypixiv_only'] as bool? ?? false,
      isXRestricted: json['is_x_restricted'] as bool? ?? false,
      novelAiType: json['novel_ai_type'] as int? ?? 0,
      series: series is JsonMap ? PixivSeries.fromJson(series) : null,
    );
  }
}

class PixivSeries {
  const PixivSeries({required this.id, required this.title});

  final String id;
  final String title;

  factory PixivSeries.fromJson(JsonMap json) {
    return PixivSeries(
      id: json['id']?.toString() ?? json['series_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}

class PixivComment {
  const PixivComment({
    required this.id,
    required this.comment,
    required this.user,
    this.date,
    this.hasReplies = false,
  });

  final String id;
  final String comment;
  final PixivUser user;
  final String? date;
  final bool hasReplies;

  factory PixivComment.fromJson(JsonMap json) {
    return PixivComment(
      id: json['id']?.toString() ?? '',
      comment: json['comment'] as String? ?? '',
      user: PixivUser.fromJson(json['user'] as JsonMap? ?? const {}),
      date: json['date'] as String?,
      hasReplies: json['has_replies'] as bool? ?? false,
    );
  }
}

class PixivBookmarkDetail {
  const PixivBookmarkDetail({
    required this.isBookmarked,
    required this.restrict,
    required this.tags,
  });

  final bool isBookmarked;
  final String restrict;
  final List<PixivBookmarkTag> tags;

  factory PixivBookmarkDetail.fromJson(JsonMap json) {
    final tags = json['tags'];

    return PixivBookmarkDetail(
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      restrict: json['restrict'] as String? ?? 'public',
      tags: tags is List
          ? tags.whereType<JsonMap>().map(PixivBookmarkTag.fromJson).toList()
          : const [],
    );
  }
}

class PixivBookmarkTag {
  const PixivBookmarkTag({
    required this.name,
    this.count = 0,
    this.isRegistered = false,
  });

  final String name;
  final int count;
  final bool isRegistered;

  factory PixivBookmarkTag.fromJson(JsonMap json) {
    return PixivBookmarkTag(
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      isRegistered: json['is_registered'] as bool? ?? false,
    );
  }
}

class PixivUserPreview {
  const PixivUserPreview({required this.user, required this.illusts});

  final PixivUser user;
  final List<PixivIllust> illusts;

  factory PixivUserPreview.fromJson(JsonMap json) {
    final illusts = json['illusts'];

    return PixivUserPreview(
      user: PixivUser.fromJson(json['user'] as JsonMap? ?? const {}),
      illusts: illusts is List
          ? illusts.whereType<JsonMap>().map(PixivIllust.fromJson).toList()
          : const [],
    );
  }
}

class PixivUserDetail {
  const PixivUserDetail({
    required this.user,
    required this.profile,
    required this.profilePublicity,
    required this.workspace,
  });

  final PixivUser user;
  final JsonMap profile;
  final JsonMap profilePublicity;
  final JsonMap workspace;

  factory PixivUserDetail.fromJson(JsonMap json) {
    return PixivUserDetail(
      user: PixivUser.fromJson(json['user'] as JsonMap? ?? const {}),
      profile: json['profile'] as JsonMap? ?? const {},
      profilePublicity: json['profile_publicity'] as JsonMap? ?? const {},
      workspace: json['workspace'] as JsonMap? ?? const {},
    );
  }
}

class PixivFollowDetail {
  const PixivFollowDetail({required this.isFollowed, required this.restrict});

  final bool isFollowed;
  final String restrict;

  factory PixivFollowDetail.fromJson(JsonMap json) {
    return PixivFollowDetail(
      isFollowed: json['is_followed'] as bool? ?? false,
      restrict: json['restrict'] as String? ?? 'public',
    );
  }
}

class PixivUgoiraMetadata {
  const PixivUgoiraMetadata({this.zipUrl, required this.frames});

  final String? zipUrl;
  final List<PixivUgoiraFrame> frames;

  factory PixivUgoiraMetadata.fromJson(JsonMap json) {
    final zipUrls = json['zip_urls'] as JsonMap? ?? const {};
    final frames = json['frames'];

    return PixivUgoiraMetadata(
      zipUrl: zipUrls['medium'] as String?,
      frames: frames is List
          ? frames.whereType<JsonMap>().map(PixivUgoiraFrame.fromJson).toList()
          : const [],
    );
  }
}

class PixivUgoiraFrame {
  const PixivUgoiraFrame({required this.file, required this.delay});

  final String file;
  final int delay;

  factory PixivUgoiraFrame.fromJson(JsonMap json) {
    return PixivUgoiraFrame(
      file: json['file'] as String? ?? '',
      delay: json['delay'] as int? ?? 0,
    );
  }
}

class PixivTrendTag {
  const PixivTrendTag({required this.tag, this.translatedName, this.illust});

  final String tag;
  final String? translatedName;
  final PixivIllust? illust;

  factory PixivTrendTag.fromJson(JsonMap json) {
    final illust = json['illust'];

    return PixivTrendTag(
      tag: json['tag'] as String? ?? '',
      translatedName: json['translated_name'] as String?,
      illust: illust is JsonMap ? PixivIllust.fromJson(illust) : null,
    );
  }
}

class PixivSpotlightArticle {
  const PixivSpotlightArticle({
    required this.id,
    required this.title,
    this.pureTitle,
    this.thumbnail,
    this.articleUrl,
    this.publishDate,
  });

  final String id;
  final String title;
  final String? pureTitle;
  final String? thumbnail;
  final String? articleUrl;
  final String? publishDate;

  factory PixivSpotlightArticle.fromJson(JsonMap json) {
    return PixivSpotlightArticle(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      pureTitle: json['pure_title'] as String?,
      thumbnail: json['thumbnail'] as String?,
      articleUrl: json['article_url'] as String?,
      publishDate: json['publish_date'] as String?,
    );
  }
}

class PixivNovelText {
  const PixivNovelText({required this.novelId, required this.text});

  final String novelId;
  final String text;

  factory PixivNovelText.fromJson(JsonMap json) {
    return PixivNovelText(
      novelId: json['novel_id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}
