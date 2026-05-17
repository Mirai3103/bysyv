import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  testWidgets('switches between all shell tabs', (tester) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search tags, titles, users...'), findsOneWidget);
    expect(find.text('Trending tags'), findsOneWidget);

    expect(find.byTooltip('Notification'), findsNothing);

    for (final tab in ['News', 'Profile']) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();

      expect(find.text(tab), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
  });
}
