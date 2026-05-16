import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  testWidgets('renders auth welcome as the entry screen', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('pixiv'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login with token'), findsOneWidget);
  });

  testWidgets('opens the Pixiv login webview route', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Pixiv Login'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Pixiv Login'), findsNothing);
    expect(find.text('pixiv'), findsOneWidget);
  });

  testWidgets('opens register webview and token auth sheet', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Pixiv Register'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Login with token'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login with token'));
    await tester.pumpAndSettle();

    expect(find.text('Refresh token'), findsOneWidget);
    expect(find.text('Authenticate'), findsOneWidget);
  });

  testWidgets('stored session bypasses auth and starts on home', (
    tester,
  ) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('pixiv'), findsNothing);
  });
}
