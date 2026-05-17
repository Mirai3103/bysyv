import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/auth_session.dart';
import '../../../../domain/models/pixiv_creator.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/artwork_card.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/profile_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(profileViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (state.isLoading)
                SliverToBoxAdapter(
                  child: Skeletonizer(
                    enabled: true,
                    child: _ProfileContent(
                      session: state.session,
                      creator: state.creator,
                      onLogout: viewModel.logout,
                    ),
                  ),
                )
              else if (state.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ProfileMessage(
                    title: 'Profile failed',
                    message: state.errorMessage!,
                    actionLabel: 'Retry',
                    onAction: viewModel.refresh,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _ProfileContent(
                    session: state.session,
                    creator: state.creator,
                    onLogout: viewModel.logout,
                  ).animate().fadeIn(delay: 80.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.session,
    required this.creator,
    required this.onLogout,
  });

  final AuthSession? session;
  final PixivCreator? creator;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final displayName = creator?.name ?? session?.userName ?? 'Pixiv User';
    final account = creator?.account ?? session?.account ?? 'pixiv';
    final avatarUrl = creator?.avatarUrl ?? session?.avatarUrl;
    final comment = _stringFromProfile('comment');
    final stats = _stats();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 68, 20, 128),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 30,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ProfileHeader(
            avatarUrl: avatarUrl,
            displayName: displayName,
            account: account,
            comment: comment,
            stats: stats,
          ),
          const SizedBox(height: 18),
          _MenuSection(
            title: 'Content',
            items: const [
              _MenuItemData(
                icon: LucideIcons.bookmark,
                label: 'Bookmarks',
                subLabel: 'Illustrations, novels',
              ),
              _MenuItemData(
                icon: LucideIcons.history,
                label: 'Browsing History',
              ),
              _MenuItemData(
                icon: LucideIcons.eye,
                label: 'My Works',
                subLabel: 'Illustrations and novels',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MenuSection(
            title: 'Settings',
            items: const [
              _MenuItemData(
                icon: LucideIcons.circleUser,
                label: 'Account Info',
                subLabel: 'Email, password, linked accounts',
              ),
              _MenuItemData(
                icon: LucideIcons.settings,
                label: 'Preferences',
                subLabel: 'Language, display, notifications',
              ),
              _MenuItemData(
                icon: LucideIcons.star,
                label: 'Favorites',
                subLabel: 'Tags, users, categories',
              ),
              _MenuItemData(
                icon: LucideIcons.volumeX,
                label: 'Mute Settings',
                subLabel: 'Muted tags, users',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MenuSection(
            items: [
              _MenuItemData(
                icon: LucideIcons.logOut,
                label: 'Log Out',
                danger: true,
                onTap: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _stringFromProfile(String key) {
    final value = creator?.profile[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  List<_ProfileStat> _stats() {
    return [
      _ProfileStat(label: 'Works', value: _profileCount('total_illusts')),
      _ProfileStat(label: 'Following', value: _profileCount('total_follow_users')),
      _ProfileStat(label: 'Followers', value: _profileCount('total_mypixiv_users')),
    ];
  }

  String _profileCount(String key) {
    final value = creator?.profile[key];
    if (value is int) return _formatCount(value);
    if (value is num) return _formatCount(value.toInt());
    return '--';
  }

  String _formatCount(int value) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatarUrl,
    required this.displayName,
    required this.account,
    required this.comment,
    required this.stats,
  });

  final String? avatarUrl;
  final String displayName;
  final String account;
  final String? comment;
  final List<_ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgPure,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1414141E),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox(
              width: 92,
              height: 92,
              child: _AvatarImage(url: avatarUrl),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@$account',
          style: const TextStyle(
            color: AppColors.inkSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (comment != null) ...[
          const SizedBox(height: 12),
          Text(
            comment!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.inkDim,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < stats.length; index++) ...[
              _StatTile(stat: stats[index]),
              if (index != stats.length - 1) const SizedBox(width: 28),
            ],
          ],
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const _AvatarFallback();

    return CachedNetworkImage(
      imageUrl: url!,
      httpHeaders: ArtworkCard.imageHeaders,
      fit: BoxFit.cover,
      placeholder: (context, url) => const _AvatarFallback(),
      errorWidget: (context, url, error) => const _AvatarFallback(),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

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
      child: Icon(LucideIcons.user, color: Colors.white, size: 34),
    );
  }
}

class _ProfileStat {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stat.value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          stat.label,
          style: const TextStyle(
            color: AppColors.inkSub,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({this.title, required this.items});

  final String? title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
            child: Text(
              title!.toUpperCase(),
              style: const TextStyle(
                color: AppColors.inkSub,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
        GlassPanel(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          strong: true,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _MenuRow(data: items[index]),
                if (index != items.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 50),
                    child: Divider(height: 1, color: Color(0x0A0A0A0A)),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.label,
    this.subLabel,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subLabel;
  final bool danger;
  final Future<void> Function()? onTap;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.data});

  final _MenuItemData data;

  @override
  Widget build(BuildContext context) {
    final color = data.danger ? const Color(0xFFEF4444) : AppColors.primary;
    final textColor = data.danger ? const Color(0xFFEF4444) : AppColors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (data.subLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.subLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!data.danger)
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.inkSubSub,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkSub),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
