import 'package:bysiv/data/services/pixiv_api_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/dio_helpers.dart';
import '../../helpers/fakes.dart';

void main() {
  group('PixivApiInterceptor', () {
    test('adds client and authorization headers when a session exists', () async {
      late RequestOptions captured;
      final dio = Dio();
      dio.interceptors.add(
        PixivApiInterceptor(
          dio: dio,
          sessionStore: MemorySessionStore(kUnitSession),
          authService: FakeAuthService(),
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(requestOptions: options, data: const {}),
            );
          },
        ),
      );

      await dio.get<dynamic>('/v1/illust/detail');

      expect(captured.headers['Authorization'], 'Bearer access');
      expect(captured.headers['Host'], 'app-api.pixiv.net');
      expect(captured.headers['X-Client-Time'], isA<String>());
      expect(captured.headers['X-Client-Hash'], isA<String>());
    });

    test(
      'allows walkthrough without auth and rejects protected requests without a session',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          PixivApiInterceptor(
            dio: dio,
            sessionStore: MemorySessionStore(null),
            authService: FakeAuthService(),
          ),
        );
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.resolve(
                Response(requestOptions: options, data: const {}),
              );
            },
          ),
        );

        await expectLater(
          dio.get<dynamic>('/v1/walkthrough/illusts'),
          completes,
        );
        await expectLater(
          dio.get<dynamic>('/v1/illust/detail'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'refreshes OAuth failures before surfacing retry transport failures',
      () async {
        final store = MemorySessionStore(kUnitSession);
        final dio = Dio();
        var attempts = 0;
        dio.interceptors.add(
          PixivApiInterceptor(
            dio: dio,
            sessionStore: store,
            authService: FakeAuthService(
              refreshed: sessionWith(accessToken: 'new-access'),
            ),
          ),
        );
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              attempts++;
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 400,
                    data: const {
                      'error': {'message': 'OAuth error: token expired'},
                    },
                  ),
                ),
              );
            },
          ),
        );

        await expectLater(
          dio.get<dynamic>('/v1/illust/detail'),
          throwsA(isA<DioException>()),
        );

        expect(attempts, greaterThanOrEqualTo(1));
        expect((await store.load())!.accessToken, 'access');
      },
    );

    test('does not refresh non-OAuth failures', () async {
      final dio = Dio();
      dio.interceptors.add(
        PixivApiInterceptor(
          dio: dio,
          sessionStore: MemorySessionStore(kUnitSession),
          authService: FakeAuthService(),
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 500,
                  data: const {},
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        dio.get<dynamic>('/v1/illust/detail'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
