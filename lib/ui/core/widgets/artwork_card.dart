import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/artwork.dart';

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({
    super.key,
    required this.artwork,
    this.compact = false,
    this.onTap,
  });

  final Artwork artwork;
  final bool compact;
  final VoidCallback? onTap;

  static const imageHeaders = {'Referer': 'https://app-api.pixiv.net/'};

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(artwork.isSpotlight ? 28 : 22);

    return Semantics(
      button: onTap != null,
      label: 'Open ${artwork.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: compact ? 0.86 : 0.74,
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
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
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _Badge(label: 'SPOTLIGHT'),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 4,
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
          ),
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
