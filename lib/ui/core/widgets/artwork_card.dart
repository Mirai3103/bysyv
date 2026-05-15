import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/artwork.dart';

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.artwork, this.compact = false});

  final Artwork artwork;
  final bool compact;

  static const imageHeaders = {'Referer': 'https://www.pixiv.net/'};

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compact ? 0.86 : 0.74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(artwork.isSpotlight ? 28 : 22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (artwork.imageUrl == null || artwork.imageUrl!.isEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: artwork.gradient,
                  ),
                ),
              )
            else
              CachedNetworkImage(
                imageUrl: artwork.imageUrl!,
                httpHeaders: imageHeaders,
                fit: BoxFit.cover,
                placeholder: (context, url) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: artwork.gradient,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: artwork.gradient,
                    ),
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Color(0x660A0A0A)],
                ),
              ),
            ),
            if (artwork.isSpotlight)
              Positioned(top: 12, left: 12, child: _Badge(label: 'SPOTLIGHT')),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    artwork.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: artwork.isSpotlight ? 19 : 14,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artwork.artist}  ·  ${(artwork.bookmarks / 1000).toStringAsFixed(1)}k',
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCCFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Icon(
                    artwork.isBookmarked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D4C5FEF),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
