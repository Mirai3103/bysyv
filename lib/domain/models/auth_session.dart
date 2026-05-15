class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.userName,
    required this.account,
    this.avatarUrl,
    this.mailAddress,
    this.isPremium = false,
    this.xRestrict = 0,
    this.isMailAuthorized = false,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String userName;
  final String account;
  final String? avatarUrl;
  final String? mailAddress;
  final bool isPremium;
  final int xRestrict;
  final bool isMailAuthorized;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      account: json['account'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      mailAddress: json['mail_address'] as String?,
      isPremium: json['is_premium'] as bool? ?? false,
      xRestrict: json['x_restrict'] as int? ?? 0,
      isMailAuthorized: json['is_mail_authorized'] as bool? ?? false,
    );
  }

  factory AuthSession.fromPixivResponse(Map<String, dynamic> json) {
    final response = json['response'] as Map<String, dynamic>? ?? {};
    final user = response['user'] as Map<String, dynamic>? ?? {};
    final imageUrls =
        user['profile_image_urls'] as Map<String, dynamic>? ?? const {};

    return AuthSession(
      accessToken: response['access_token'] as String? ?? '',
      refreshToken: response['refresh_token'] as String? ?? '',
      userId: user['id']?.toString() ?? '',
      userName: user['name'] as String? ?? '',
      account: user['account'] as String? ?? '',
      avatarUrl:
          imageUrls['px_170x170'] as String? ??
          imageUrls['px_50x50'] as String? ??
          imageUrls['medium'] as String?,
      mailAddress: user['mail_address'] as String?,
      isPremium: user['is_premium'] as bool? ?? false,
      xRestrict: user['x_restrict'] as int? ?? 0,
      isMailAuthorized: user['is_mail_authorized'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
      'user_name': userName,
      'account': account,
      'avatar_url': avatarUrl,
      'mail_address': mailAddress,
      'is_premium': isPremium,
      'x_restrict': xRestrict,
      'is_mail_authorized': isMailAuthorized,
    };
  }
}
