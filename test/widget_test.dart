import 'package:bysiv/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('renders the initialized discover shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BysivApp()));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Search artists, tags...'), findsOneWidget);
    expect(find.text('For you'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
  });

  testWidgets('switches between shell tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BysivApp()));
    await tester.pumpAndSettle();

    for (final tab in ['Search', 'News', 'Notification', 'Profile']) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();

      expect(find.text(tab), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
  });
}
