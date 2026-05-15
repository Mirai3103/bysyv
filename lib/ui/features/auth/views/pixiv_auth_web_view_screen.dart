import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/pixiv_auth_service.dart';
import '../../../core/widgets/app_button.dart';
import '../view_models/auth_controller.dart';

class PixivAuthWebViewScreen extends ConsumerStatefulWidget {
  const PixivAuthWebViewScreen({super.key, required this.mode});

  final PixivWebAuthMode mode;

  @override
  ConsumerState<PixivAuthWebViewScreen> createState() {
    return _PixivAuthWebViewScreenState();
  }
}

class _PixivAuthWebViewScreenState
    extends ConsumerState<PixivAuthWebViewScreen> {
  late final PixivAuthRequest _request;
  WebViewController? _webViewController;
  String? _webViewError;
  var _progress = 0;
  var _isExchanging = false;

  @override
  void initState() {
    super.initState();
    _request = ref.read(authControllerProvider).startWebLogin(widget.mode);
    _configureWebView();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/home');
      }
    });

    final title = widget.mode == PixivWebAuthMode.login
        ? 'Pixiv Login'
        : 'Pixiv Register';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgPure,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrowLeft),
          color: AppColors.ink,
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(LucideIcons.refreshCw),
            color: AppColors.ink,
            onPressed: _webViewController?.reload,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.centerLeft,
            height: 3,
            child: FractionallySizedBox(
              widthFactor: _progress <= 0 ? 0 : _progress / 100,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_webViewController == null)
            _WebViewFallback(error: _webViewError, onBack: () => context.pop())
          else
            WebViewWidget(controller: _webViewController!),
          if (_isExchanging || auth.isBusy)
            const _AuthExchangeOverlay(message: 'Signing in with Pixiv...'),
          if (auth.errorMessage != null && !_isExchanging)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18 + MediaQuery.paddingOf(context).bottom,
              child: _AuthErrorBanner(message: auth.errorMessage!),
            ),
        ],
      ),
    );
  }

  void _configureWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.bgPure)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _progress = progress);
            },
            onNavigationRequest: _handleNavigationRequest,
          ),
        )
        ..loadRequest(_request.url);
      _webViewController = controller;
    } catch (error) {
      _webViewError = error.toString();
    }
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null || uri.scheme != 'pixiv') {
      return NavigationDecision.navigate;
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      setState(() => _webViewError = 'Pixiv callback did not include a code.');
      return NavigationDecision.prevent;
    }

    _exchangeCode(code);
    return NavigationDecision.prevent;
  }

  Future<void> _exchangeCode(String code) async {
    if (_isExchanging) return;
    setState(() => _isExchanging = true);
    await ref
        .read(authControllerProvider)
        .exchangeAuthorizationCode(
          code: code,
          codeVerifier: _request.codeVerifier,
        );
    if (mounted) {
      setState(() => _isExchanging = false);
    }
  }
}

class _AuthExchangeOverlay extends StatelessWidget {
  const _AuthExchangeOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgPure.withValues(alpha: 0.82),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassStrong,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgPure,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x26E34B61)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A14141E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(LucideIcons.circleAlert, color: Color(0xFFE34B61)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.inkDim, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebViewFallback extends StatelessWidget {
  const _WebViewFallback({required this.error, required this.onBack});

  final String? error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.globeLock, color: AppColors.primary),
            const SizedBox(height: 14),
            const Text(
              'WebView is not available in this environment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSub, fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            AppButton(
              label: 'Back',
              onPressed: onBack,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
