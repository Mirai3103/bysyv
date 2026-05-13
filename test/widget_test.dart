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
}
