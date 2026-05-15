import 'artwork.dart';

class TrendTag {
  const TrendTag({required this.tag, this.translatedName, this.artwork});

  final String tag;
  final String? translatedName;
  final Artwork? artwork;
}
