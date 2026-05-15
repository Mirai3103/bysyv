import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/pixiv_auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_bottom_sheet_overlay.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass_panel.dart';
import '../view_models/auth_controller.dart';

enum _AuthStage { welcome, token }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _stage = _AuthStage.welcome;

  void _closeSheet() {
    setState(() => _stage = _AuthStage.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _AuthWelcome(
            onLogin: () {
              context.push('/auth/web', extra: PixivWebAuthMode.login);
            },
            onRegister: () {
              context.push('/auth/web', extra: PixivWebAuthMode.register);
            },
            onToken: () => setState(() => _stage = _AuthStage.token),
          ),
          if (_stage == _AuthStage.token) _TokenSheet(onBack: _closeSheet),
        ],
      ),
    );
  }
}

class _AuthWelcome extends StatelessWidget {
  const _AuthWelcome({
    required this.onLogin,
    required this.onRegister,
    required this.onToken,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onToken;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 32 + MediaQuery.paddingOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const _AuthHero(),
                    const _WordmarkBlock(),
                    _AuthActions(
                      onLogin: onLogin,
                      onRegister: onRegister,
                      onToken: onToken,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
          height: 320,
          margin: const EdgeInsets.fromLTRB(16, 54, 16, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1414141E),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 6,
                      child: _HeroTile(index: 0, width: 220, height: 300),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                            child: _HeroTile(index: 1, width: 160, height: 140),
                          ),
                          SizedBox(height: 4),
                          Expanded(
                            child: _HeroTile(index: 2, width: 160, height: 140),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00FCFBF8),
                        Color(0xBFFCFBF8),
                        Color(0xF2FCFBF8),
                      ],
                      stops: [0.35, 0.85, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.97, 0.97),
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.index,
    required this.width,
    required this.height,
  });

  final int index;
  final int width;
  final int height;

  @override
  Widget build(BuildContext context) {
    final gradients = const [
      [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
      [Color(0xFFD5E8F5), Color(0xFF7494B5)],
      [Color(0xFFFFE2E8), Color(0xFFB8717F)],
    ];
    final colors = gradients[index % gradients.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(index == 0 ? 20 : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Image.network(
          _waifuUrl(index, width, height),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.expand();
          },
        ),
      ),
    );
  }

  String _waifuUrl(int index, int width, int height) {
    final offsetWidth = (index * 7) % 17;
    final offsetHeight = (index * 11) % 13;
    return 'https://placewaifu.com/image/${width + offsetWidth}/${height + offsetHeight}';
  }
}

class _WordmarkBlock extends StatelessWidget {
  const _WordmarkBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Transform.translate(
            offset: const Offset(0, -28),
            child: Column(
              children: [
                const Text(
                  'pixiv',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Discover illustrations, manga & novels',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkDim,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'your way',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 80.ms)
        .slideY(begin: 0.08, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({
    required this.onLogin,
    required this.onRegister,
    required this.onToken,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onToken;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
          offset: const Offset(0, -8),
          child: GlassPanel(
            radius: 36,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            strong: true,
            child: Column(
              children: [
                AppButton(label: 'Login', onPressed: onLogin),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Register',
                  onPressed: onRegister,
                  variant: AppButtonVariant.secondary,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Login with token',
                  onPressed: onToken,
                  variant: AppButtonVariant.ghost,
                  icon: LucideIcons.key,
                  height: 46,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Third-party client · Not affiliated with Pixiv Inc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.inkSub,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 160.ms)
        .slideY(begin: 0.12, duration: 650.ms, curve: Curves.easeOutCubic);
  }
}

class _TokenSheet extends ConsumerStatefulWidget {
  const _TokenSheet({required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<_TokenSheet> createState() => _TokenSheetState();
}

class _TokenSheetState extends ConsumerState<_TokenSheet> {
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/home');
      }
    });

    return AppBottomSheetOverlay(
      title: 'Login with token',
      subtitle:
          'Paste a refresh token from an existing OAuth session — common in third-party clients',
      onBack: widget.onBack,
      children: [
        AppTextField(
          label: 'Refresh token',
          placeholder: 'Paste refresh_token here...',
          controller: _tokenController,
          minLines: 5,
          maxLines: 5,
          monospace: true,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            border: Border.all(color: AppColors.primaryBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              'Tip: Token login skips the browser OAuth flow. Never share tokens publicly.',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 11,
                height: 1.55,
              ),
            ),
          ),
        ),
        if (auth.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            auth.errorMessage!,
            style: const TextStyle(color: Color(0xFFE34B61), fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: auth.isBusy ? 'Authenticating...' : 'Authenticate',
          onPressed: auth.isBusy ? null : _loginWithToken,
        ),
      ],
    );
  }

  void _loginWithToken() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    ref.read(authControllerProvider).loginWithRefreshToken(token);
  }
}
