import 'pixiv_creator.dart';
import 'pixiv_tag.dart';

class Novel {
  const Novel({
    required this.id,
    required this.title,
    required this.author,
    required this.bookmarks,
    this.caption = '',
    this.imageUrl,
    this.pageCount = 0,
    this.textLength = 0,
    this.totalView = 0,
    this.totalComments = 0,
    this.isBookmarked = false,
    this.tags = const [],
  });

  final String id;
  final String title;
  final PixivCreator author;
  final int bookmarks;
  final String caption;
  final String? imageUrl;
  final int pageCount;
  final int textLength;
  final int totalView;
  final int totalComments;
  final bool isBookmarked;
  final List<PixivTag> tags;
}
