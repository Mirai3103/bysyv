import 'package:bysiv/domain/models/artwork.dart';
import 'package:bysiv/ui/core/widgets/artwork_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const baseArtwork = Artwork(
    id: 'a-1',
    title: 'Blue Hour',
    artist: 'Mika',
    bookmarks: 1200,
    gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
  );

  testWidgets('renders title and artist', (tester) async {
    await tester.pumpWidget(wrap(ArtworkCard(artwork: baseArtwork)));
    expect(find.text('Blue Hour'), findsOneWidget);
    expect(find.textContaining('Mika'), findsOneWidget);
  });

  testWidgets('shows bookmark icon when bookmarked', (tester) async {
    const bookmarked = Artwork(
      id: 'a-2',
      title: 'Test',
      artist: 'Aki',
      bookmarks: 500,
      gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
      isBookmarked: true,
    );
    await tester.pumpWidget(wrap(ArtworkCard(artwork: bookmarked)));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('shows border bookmark icon when not bookmarked', (tester) async {
    await tester.pumpWidget(wrap(ArtworkCard(artwork: baseArtwork)));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('shows SPOTLIGHT badge for spotlight artwork', (tester) async {
    const spotlight = Artwork(
      id: 'a-3',
      title: 'Spotlight Art',
      artist: 'Mika',
      bookmarks: 9000,
      gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
      isSpotlight: true,
    );
    await tester.pumpWidget(wrap(ArtworkCard(artwork: spotlight)));
    expect(find.text('SPOTLIGHT'), findsOneWidget);
  });

  testWidgets('does not show SPOTLIGHT badge for normal artwork', (tester) async {
    await tester.pumpWidget(wrap(ArtworkCard(artwork: baseArtwork)));
    expect(find.text('SPOTLIGHT'), findsNothing);
  });

  testWidgets('compact variant renders without error', (tester) async {
    await tester.pumpWidget(
      wrap(ArtworkCard(artwork: baseArtwork, compact: true)),
    );
    expect(find.text('Blue Hour'), findsOneWidget);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(ArtworkCard(artwork: baseArtwork, onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(ArtworkCard));
    expect(tapped, isTrue);
  });

  testWidgets('renders gradient placeholder when imageUrl is null', (tester) async {
    await tester.pumpWidget(wrap(ArtworkCard(artwork: baseArtwork)));
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  testWidgets('renders with imageUrl set', (tester) async {
    const withImage = Artwork(
      id: 'a-4',
      title: 'With Image',
      artist: 'Mika',
      bookmarks: 300,
      gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
      imageUrl: 'https://example.com/image.jpg',
    );
    await tester.pumpWidget(wrap(ArtworkCard(artwork: withImage)));
    expect(find.text('With Image'), findsOneWidget);
  });
}
