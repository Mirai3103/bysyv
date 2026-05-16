import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('renders the initialized discover shell', (tester) async {
    await pumpHome(tester);

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Search artists, tags...'), findsNothing);
    expect(find.text('Recommend'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
  });

  testWidgets('updates the active home filter pill', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();

    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
  });
}
