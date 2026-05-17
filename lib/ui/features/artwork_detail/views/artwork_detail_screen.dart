import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/artwork.dart';
import '../../../../domain/models/artwork_detail.dart';
import '../../../../domain/models/pixiv_comment.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/artwork_detail_view_model.dart';

class ArtworkDetailScreen extends ConsumerStatefulWidget {
  const ArtworkDetailScreen({super.key, required this.illustId});

  final String illustId;

  @override
  ConsumerState<ArtworkDetailScreen> createState() =>
      _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends ConsumerState<ArtworkDetailScreen> {
  final _scrollController = ScrollController();
  var _activePage = 1;
  var _liked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(
      artworkDetailViewModelProvider(widget.illustId),
    );
    final state = viewModel.state;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            if (state.isLoading && state.detail == null)
              const _DetailSkeleton()
            else if (state.detail == null)
              _DetailError(
                message: state.errorMessage ?? 'Artwork not found.',
                onRetry: viewModel.load,
              )
            else
              _DetailContent(
                controller: _scrollController,
                detail: state.detail!,
                activePage: _activePage,
                liked: _liked,
                isBookmarking: state.isBookmarking,
                isFollowing: state.isFollowing,
                onLike: () => setState(() => _liked = !_liked),
                onBookmark: viewModel.toggleBookmark,
                onFollow: viewModel.toggleFollow,
              ),
            if (state.hasError && state.detail != null)
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 72,
                child: _InlineError(message: state.errorMessage!),
              ),
          ],
        ),
      ),
    );
  }

  void _handleScroll() {
    final detail = ref
        .read(artworkDetailViewModelProvider(widget.illustId))
        .state
        .detail;
    final totalPages = detail?.pages.length ?? 1;
    final position = _scrollController.position;
    final nextOffset = _scrollController.offset;
    var nextPage = 1;
    if (position.maxScrollExtent > 0 && totalPages > 1) {
      nextPage =
          ((nextOffset / math.max(1, position.maxScrollExtent)) * totalPages)
              .floor() +
          1;
      nextPage = nextPage.clamp(1, totalPages);
    }

    if (nextPage != _activePage) {
      setState(() {
        _activePage = nextPage;
      });
    }
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.controller,
    required this.detail,
    required this.activePage,
    required this.liked,
    required this.isBookmarking,
    required this.isFollowing,
    required this.onLike,
    required this.onBookmark,
    required this.onFollow,
  });

  final ScrollController controller;
  final ArtworkDetail detail;
  final int activePage;
  final bool liked;
  final bool isBookmarking;
  final bool isFollowing;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _PageList(pages: detail.pages)),
            SliverToBoxAdapter(
              child: _MetaBlock(
                detail: detail,
                isFollowing: isFollowing,
                onFollow: onFollow,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                child: _ActionBar(
                  artwork: detail.artwork,
                  liked: liked,
                  isBookmarking: isBookmarking,
                  onLike: onLike,
                  onBookmark: onBookmark,
                ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
              ),
            ),
            SliverToBoxAdapter(
              child: _CommentsSection(comments: detail.comments),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: _RelatedGrid(related: detail.related),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _DetailTopBar(
            activePage: activePage,
            totalPages: detail.pages.length,
          ),
        ),
      ],
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.activePage, required this.totalPages});

  final int activePage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            _GlassIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Back',
              onTap: () => context.pop(),
            ),
            const Spacer(),
            if (totalPages > 1)
              GlassPanel(
                radius: 999,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                strong: true,
                child: Text(
                  '$activePage / $totalPages',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const Spacer(),
            _GlassIconButton(
              icon: Icons.share_outlined,
              tooltip: 'Share',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: Icons.more_horiz,
              tooltip: 'More',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _PageList extends StatelessWidget {
  const _PageList({required this.pages});

  final List<ArtworkImagePage> pages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < pages.length; index++)
          Padding(
            padding: EdgeInsets.only(bottom: index == pages.length - 1 ? 0 : 4),
            child: AspectRatio(
              aspectRatio: pages[index].aspectRatio,
              child: CachedNetworkImage(
                imageUrl: pages[index].imageUrl,
                httpHeaders: ArtworkCard.imageHeaders,
                fit: BoxFit.cover,
                placeholder: (context, url) => const _ImagePlaceholder(),
                errorWidget: (context, url, error) => const _ImagePlaceholder(),
              ),
            ),
          ).animate().fadeIn(delay: (70 * index).ms).slideY(begin: 0.04),
      ],
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({
    required this.detail,
    required this.isFollowing,
    required this.onFollow,
  });

  final ArtworkDetail detail;
  final bool isFollowing;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final caption = detail.caption;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.artwork.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.22,
            ),
          ).animate().fadeIn().slideY(begin: 0.08),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _Stat(
                icon: Icons.visibility_outlined,
                label: _formatCount(detail.totalView),
              ),
              _Stat(
                icon: Icons.favorite_border,
                label: _formatCount(detail.totalBookmarks),
              ),
              _Stat(
                icon: Icons.bookmark_border,
                label: '${_formatCount(detail.totalBookmarks)} saved',
              ),
              if (detail.createDate != null)
                _Stat(
                  icon: Icons.calendar_today,
                  label: _formatDate(detail.createDate!),
                ),
            ],
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 18),
          _ArtistFollowBar(
            detail: detail,
            isFollowing: isFollowing,
            onFollow: onFollow,
          ),
          const SizedBox(height: 18),
          _Tags(tags: detail.tags.map((tag) => tag.name).toList()),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              caption,
              style: const TextStyle(
                color: AppColors.inkDim,
                fontSize: 14,
                height: 1.55,
              ),
            ).animate().fadeIn(delay: 140.ms),
          ],
        ],
      ),
    );
  }
}

class _ArtistFollowBar extends StatelessWidget {
  const _ArtistFollowBar({
    required this.detail,
    required this.isFollowing,
    required this.onFollow,
  });

  final ArtworkDetail detail;
  final bool isFollowing;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: GlassPanel(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        strong: true,
        child: Row(
          children: [
            _Avatar(url: detail.creator.avatarUrl, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    detail.creator.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Illustrator',
                    style: TextStyle(color: AppColors.inkSub, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isFollowing ? null : onFollow,
              style: FilledButton.styleFrom(
                backgroundColor: detail.creator.isFollowed
                    ? AppColors.primarySoft
                    : AppColors.primary,
                foregroundColor: detail.creator.isFollowed
                    ? AppColors.primary
                    : Colors.white,
                disabledBackgroundColor: AppColors.primarySoft,
                disabledForegroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(detail.creator.isFollowed ? 'Following' : 'Follow'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 180.ms).slideY(begin: -0.12);
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TAGS',
          style: TextStyle(
            color: AppColors.inkSub,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              GlassPanel(
                radius: 999,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 120.ms);
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({required this.comments});

  final List<PixivComment> comments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Comments',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (comments.isEmpty)
            const Text(
              'No comments yet.',
              style: TextStyle(color: AppColors.inkSub, fontSize: 13),
            )
          else
            for (var index = 0; index < comments.length; index++) ...[
              _CommentCard(
                comment: comments[index],
              ).animate().fadeIn(delay: (90 * index).ms).slideY(begin: 0.08),
              const SizedBox(height: 10),
            ],
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBorder),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text(
                  'Add a comment...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final PixivComment comment;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(url: comment.user.avatarUrl, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (comment.date != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(comment.date!),
                        style: const TextStyle(
                          color: AppColors.inkSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: AppColors.inkDim,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedGrid extends StatelessWidget {
  const _RelatedGrid({required this.related});

  final List<Artwork> related;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Related',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'GET /v2/illust/related',
                  style: TextStyle(color: AppColors.inkSub, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (related.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'No related artworks.',
                style: TextStyle(color: AppColors.inkSub),
              ),
            ),
          )
        else
          SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final artwork = related[index];
              return ArtworkCard(
                artwork: artwork,
                compact: index.isEven,
                onTap: () => context.push('/artworks/${artwork.id}'),
              ).animate().fadeIn(delay: (60 * (index % 6)).ms);
            }, childCount: related.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.artwork,
    required this.liked,
    required this.isBookmarking,
    required this.onLike,
    required this.onBookmark,
  });

  final Artwork artwork;
  final bool liked;
  final bool isBookmarking;
  final VoidCallback onLike;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      strong: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: liked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(artwork.bookmarks),
            active: liked,
            onTap: onLike,
          ),
          _ActionButton(
            icon: artwork.isBookmarked
                ? Icons.bookmark
                : Icons.bookmark_border,
            label: isBookmarking
                ? 'Saving'
                : artwork.isBookmarked
                ? 'Saved'
                : 'Save',
            active: artwork.isBookmarked,
            onTap: isBookmarking ? null : onBookmark,
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Comment',
            active: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.inkSub;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.1 : 1,
              duration: 180.ms,
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.inkSub, size: 15),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkDim,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: AppColors.ink, size: 20),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url!.isEmpty
            ? const ColoredBox(
                color: AppColors.primarySoft,
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                httpHeaders: ArtworkCard.imageHeaders,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const ColoredBox(
                  color: AppColors.primarySoft,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 86, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AspectRatio(aspectRatio: 0.76, child: _ImagePlaceholder()),
                    SizedBox(height: 20),
                    Text(
                      'Artwork title placeholder',
                      style: TextStyle(fontSize: 22),
                    ),
                    SizedBox(height: 12),
                    Text('1.2k  3.4k saved  2026-05-15'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.primary,
                size: 34,
              ),
              const SizedBox(height: 14),
              const Text(
                'Artwork failed',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.inkSub),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.all(12),
      strong: true,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE34B61)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkDim, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 10000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}

String _formatDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
