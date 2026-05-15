class BookmarkDetail {
  const BookmarkDetail({
    required this.isBookmarked,
    required this.restrict,
    required this.tags,
  });

  final bool isBookmarked;
  final String restrict;
  final List<BookmarkTag> tags;
}

class BookmarkTag {
  const BookmarkTag({
    required this.name,
    this.count = 0,
    this.isRegistered = false,
  });

  final String name;
  final int count;
  final bool isRegistered;
}
