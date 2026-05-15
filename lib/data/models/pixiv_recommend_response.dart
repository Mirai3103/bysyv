import 'pixiv_common_models.dart';
export 'pixiv_common_models.dart' show PixivIllust;

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
