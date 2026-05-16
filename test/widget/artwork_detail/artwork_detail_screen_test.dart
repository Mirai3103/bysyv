import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import 'package:flutter/material.dart';
import '../../helpers/pump.dart';

void main() {
  testWidgets('opens artwork detail from a home artwork card', (tester) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await openFirstArtworkDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('bookmark button toggles saved state', (tester) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await openFirstArtworkDetail(tester);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
  });
}
