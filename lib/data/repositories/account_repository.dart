import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/auth_session.dart';
import '../models/pixiv_account_models.dart';
import '../services/pixiv_account_service.dart';
import '../services/pixiv_auth_service.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    accountService: ref.watch(pixivAccountServiceProvider),
    authService: ref.watch(pixivAuthServiceProvider),
  );
});

class AccountRepository {
  AccountRepository({
    required PixivAccountService accountService,
    required PixivAuthService authService,
  }) : _accountService = accountService,
       _authService = authService;

  final PixivAccountService _accountService;
  final PixivAuthService _authService;

  Future<PixivProvisionalAccount> createProvisionalAccount({
    required String userName,
  }) {
    return _accountService.createProvisionalAccount(userName: userName);
  }

  Future<void> editAccount({
    required String currentPassword,
    String? newMailAddress,
    String? newUserAccount,
    String? newPassword,
  }) async {
    final response = await _accountService.editAccount(
      currentPassword: currentPassword,
      newMailAddress: newMailAddress,
      newUserAccount: newUserAccount,
      newPassword: newPassword,
    );
    if (response.hasError) {
      throw PixivAccountException(response.message);
    }
  }

  Future<AuthSession> loginProvisionalAccount(PixivProvisionalAccount account) {
    return _authService.loginWithPassword(
      username: account.userAccount,
      password: account.password,
      deviceToken: account.deviceToken,
    );
  }
}
