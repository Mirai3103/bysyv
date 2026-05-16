import 'artwork.dart';
import 'pixiv_creator.dart';

class SearchUserResult {
  const SearchUserResult({
    required this.creator,
    this.previewArtworks = const [],
  });

  final PixivCreator creator;
  final List<Artwork> previewArtworks;
}
