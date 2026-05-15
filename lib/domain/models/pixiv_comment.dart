import 'pixiv_creator.dart';

class PixivComment {
  const PixivComment({
    required this.id,
    required this.body,
    required this.user,
    this.date,
    this.hasReplies = false,
  });

  final String id;
  final String body;
  final PixivCreator user;
  final String? date;
  final bool hasReplies;
}
