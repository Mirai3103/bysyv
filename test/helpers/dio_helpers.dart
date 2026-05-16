import 'package:bysiv/data/repositories/auth_session_store.dart';
import 'package:bysiv/domain/models/auth_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Builds a [Dio] that replays [responses] in order and records
/// every [RequestOptions] into [seen].
Dio dioWithResponses(
  List<RequestOptions> seen,
  List<Map<String, dynamic>> responses,
) {
  final queue = [...responses];
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        seen.add(options);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            data: queue.removeAt(0),
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return dio;
}

/// Builds a [Dio] that replays nullable responses (null → empty map).
Dio dioWithNullableResponses(List<Map<String, dynamic>?> responses) {
  final queue = [...responses];
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<Map<String, dynamic>?>(
            requestOptions: options,
            data: queue.removeAt(0),
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return dio;
}

/// Builds a [Dio] that always rejects with a [DioException] carrying [data].
Dio dioWithDioError(Map<String, dynamic> data) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Map<String, dynamic>>(
              requestOptions: options,
              data: data,
              statusCode: 400,
            ),
          ),
        );
      },
    ),
  );
  return dio;
}

/// In-memory [AuthSessionStore] for unit tests.
class MemorySessionStore extends AuthSessionStore {
  MemorySessionStore(this.session)
    : super(storage: const FlutterSecureStorage());

  AuthSession? session;

  @override
  Future<AuthSession?> load() async => session;

  @override
  Future<void> save(AuthSession session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}

const kUnitSession = AuthSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  userId: 'user-1',
  userName: 'Mika',
  account: 'mika',
);

AuthSession sessionWith({String accessToken = 'access'}) => AuthSession(
  accessToken: accessToken,
  refreshToken: 'refresh',
  userId: 'user-1',
  userName: 'Mika',
  account: 'mika',
);

Map<String, dynamic> authResponseJson(String accessToken) => {
  'response': {
    'access_token': accessToken,
    'refresh_token': 'refresh',
    'user': {
      'id': 'user-1',
      'name': 'Mika',
      'account': 'mika',
      'profile_image_urls': {'medium': 'avatar.jpg'},
    },
  },
};
