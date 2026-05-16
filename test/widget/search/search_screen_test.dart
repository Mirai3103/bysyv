import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  testWidgets('loads trending tags and autocomplete suggestions', (
    tester,
  ) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('初音ミク'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'miku');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('miku'), findsWidgets);
    expect(find.text('miku original'), findsOneWidget);
  });

  testWidgets('stores five recent words and supports clear', (tester) async {
    final recentStore = FakeSearchRecentStore();

    await pumpApp(tester, session: kTestSession, searchRecentStore: recentStore);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    for (final word in [
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'three',
    ]) {
      await tester.enterText(find.byType(TextField), word);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump(const Duration(milliseconds: 40));
    }

    expect(recentStore.words, ['three', 'six', 'five', 'four', 'two']);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('three'), findsWidgets);
    expect(find.text('one'), findsNothing);

    await tester.tap(find.text('Clear all'));
    await tester.pump();

    expect(recentStore.words, isEmpty);
    expect(find.text('No recent searches'), findsOneWidget);
  });

  testWidgets('submit shows artwork, novel, and user result tabs', (
    tester,
  ) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'miku');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Artwork'), findsOneWidget);
    expect(find.text('Novel'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('1 artworks loaded'), findsOneWidget);
  });

  testWidgets('artwork result opens artwork detail', (tester) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'miku');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-artwork-search-1')));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('novel and user results open placeholder screens', (
    tester,
  ) async {
    await pumpApp(tester, session: kTestSession);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'miku');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-novel-novel-1')));
    await tester.pumpAndSettle();

    expect(find.text('Novel detail novel-1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-user-user-1')));
    await tester.pumpAndSettle();

    expect(find.text('User profile user-1'), findsOneWidget);
  });
}
