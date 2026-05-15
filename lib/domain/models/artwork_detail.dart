import 'artwork.dart';
import 'pixiv_comment.dart';
import 'pixiv_creator.dart';
import 'pixiv_tag.dart';

class ArtworkImagePage {
  const ArtworkImagePage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final int width;
  final int height;

  double get aspectRatio {
    if (width <= 0 || height <= 0) return 0.76;
    return width / height;
  }
}

class ArtworkDetail {
  const ArtworkDetail({
    required this.artwork,
    required this.creator,
    required this.tags,
    required this.pages,
    required this.related,
    required this.comments,
    this.caption,
    this.createDate,
    this.totalView = 0,
    this.totalBookmarks = 0,
    this.totalComments = 0,
  });

  final Artwork artwork;
  final PixivCreator creator;
  final List<PixivTag> tags;
  final List<ArtworkImagePage> pages;
  final List<Artwork> related;
  final List<PixivComment> comments;
  final String? caption;
  final String? createDate;
  final int totalView;
  final int totalBookmarks;
  final int totalComments;

  ArtworkDetail copyWith({
    Artwork? artwork,
    PixivCreator? creator,
    List<PixivTag>? tags,
    List<ArtworkImagePage>? pages,
    List<Artwork>? related,
    List<PixivComment>? comments,
    String? caption,
    String? createDate,
    int? totalView,
    int? totalBookmarks,
    int? totalComments,
  }) {
    return ArtworkDetail(
      artwork: artwork ?? this.artwork,
      creator: creator ?? this.creator,
      tags: tags ?? this.tags,
      pages: pages ?? this.pages,
      related: related ?? this.related,
      comments: comments ?? this.comments,
      caption: caption ?? this.caption,
      createDate: createDate ?? this.createDate,
      totalView: totalView ?? this.totalView,
      totalBookmarks: totalBookmarks ?? this.totalBookmarks,
      totalComments: totalComments ?? this.totalComments,
    );
  }
}
