class PixivProvisionalAccount {
  const PixivProvisionalAccount({
    required this.userAccount,
    required this.password,
    required this.deviceToken,
  });

  final String userAccount;
  final String password;
  final String deviceToken;

  factory PixivProvisionalAccount.fromJson(Map<String, dynamic> json) {
    return PixivProvisionalAccount(
      userAccount: json['user_account'] as String? ?? '',
      password: json['password'] as String? ?? '',
      deviceToken: json['device_token'] as String? ?? '',
    );
  }
}

class PixivAccountResponse {
  const PixivAccountResponse({
    required this.hasError,
    required this.message,
    required this.body,
  });

  final bool hasError;
  final String message;
  final Map<String, dynamic> body;

  factory PixivAccountResponse.fromJson(Map<String, dynamic> json) {
    return PixivAccountResponse(
      hasError: json['error'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      body: json['body'] as Map<String, dynamic>? ?? const {},
    );
  }
}
