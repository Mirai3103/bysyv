import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/repositories/auth_session_store.dart';
import '../../../../data/services/pixiv_auth_service.dart';
import '../../../../domain/models/auth_session.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    authService: ref.watch(pixivAuthServiceProvider),
    sessionStore: ref.watch(authSessionStoreProvider),
  );
  controller.loadSession();
  return controller;
});

enum AuthStatus { initializing, unauthenticated, authenticating, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required PixivAuthService authService,
    required AuthSessionStore sessionStore,
  }) : _authService = authService,
       _sessionStore = sessionStore;

  final PixivAuthService _authService;
  final AuthSessionStore _sessionStore;

  AuthStatus _status = AuthStatus.initializing;
  AuthSession? _session;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _status != AuthStatus.initializing;
  bool get isAuthenticated => _session != null;
  bool get isBusy => _status == AuthStatus.authenticating;

  Future<void> loadSession() async {
    final session = await _sessionStore.load();
    _session = session;
    _status = session == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  PixivAuthRequest startWebLogin(PixivWebAuthMode mode) {
    _errorMessage = null;
    return _authService.createWebAuthRequest(mode);
  }

  Future<void> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async {
    await _authenticate(() {
      return _authService.exchangeAuthorizationCode(
        code: code,
        codeVerifier: codeVerifier,
      );
    });
  }

  Future<void> loginWithRefreshToken(String refreshToken) async {
    await _authenticate(() => _authService.refreshToken(refreshToken));
  }

  Future<void> logout() async {
    await _sessionStore.clear();
    _session = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _authenticate(Future<AuthSession> Function() action) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await action();
      if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
        throw PixivAuthException('Pixiv did not return a usable token.');
      }
      await _sessionStore.save(session);
      _session = session;
      _status = AuthStatus.authenticated;
    } catch (error) {
      _session = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }
}
