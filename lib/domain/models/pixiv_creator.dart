class PixivCreator {
  const PixivCreator({
    required this.id,
    required this.name,
    required this.account,
    this.avatarUrl,
    this.isFollowed = false,
    this.profile = const {},
    this.profilePublicity = const {},
    this.workspace = const {},
  });

  final String id;
  final String name;
  final String account;
  final String? avatarUrl;
  final bool isFollowed;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> profilePublicity;
  final Map<String, dynamic> workspace;
}
