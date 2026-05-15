class PixivRecommendResponse {
  const PixivRecommendResponse({required this.illusts, this.nextUrl});

  final List<PixivIllust> illusts;
  final String? nextUrl;

  factory PixivRecommendResponse.fromJson(Map<String, dynamic> json) {
    final illusts = json['illusts'];

    return PixivRecommendResponse(
      illusts: illusts is List
          ? illusts
                .whereType<Map<String, dynamic>>()
                .map(PixivIllust.fromJson)
                .toList()
          : const [],
      nextUrl: json['next_url'] as String?,
    );
  }
}

class PixivIllust {
  const PixivIllust({
    required this.id,
    required this.title,
    required this.artistName,
    required this.totalBookmarks,
    this.imageUrl,
    this.pageCount = 1,
    this.isBookmarked = false,
    this.xRestrict = 0,
  });

  final String id;
  final String title;
  final String artistName;
  final int totalBookmarks;
  final String? imageUrl;
  final int pageCount;
  final bool isBookmarked;
  final int xRestrict;

  factory PixivIllust.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final imageUrls = json['image_urls'] as Map<String, dynamic>? ?? const {};

    return PixivIllust(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      artistName: user['name'] as String? ?? '',
      totalBookmarks: json['total_bookmarks'] as int? ?? 0,
      imageUrl:
          imageUrls['large'] as String? ??
          imageUrls['medium'] as String? ??
          imageUrls['square_medium'] as String?,
      pageCount: json['page_count'] as int? ?? 1,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      xRestrict: json['x_restrict'] as int? ?? 0,
    );
  }
}
