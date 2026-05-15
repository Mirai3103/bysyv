class FeedPage<T> {
  const FeedPage({required this.items, this.nextUrl});

  final List<T> items;
  final String? nextUrl;
}
