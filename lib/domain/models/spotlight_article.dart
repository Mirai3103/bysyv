class SpotlightArticle {
  const SpotlightArticle({
    required this.id,
    required this.title,
    this.pureTitle,
    this.thumbnailUrl,
    this.articleUrl,
    this.publishDate,
  });

  final String id;
  final String title;
  final String? pureTitle;
  final String? thumbnailUrl;
  final String? articleUrl;
  final String? publishDate;
}
