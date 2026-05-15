import 'package:flutter/material.dart';

class Artwork {
  const Artwork({
    required this.id,
    required this.title,
    required this.artist,
    required this.bookmarks,
    required this.gradient,
    this.imageUrl,
    this.pageCount = 1,
    this.isBookmarked = false,
    this.xRestrict = 0,
    this.isSpotlight = false,
  });

  final String id;
  final String title;
  final String artist;
  final int bookmarks;
  final List<Color> gradient;
  final String? imageUrl;
  final int pageCount;
  final bool isBookmarked;
  final int xRestrict;
  final bool isSpotlight;

  static const samples = [
    Artwork(
      id: 'spotlight',
      title: 'Blue hour signal',
      artist: 'mika',
      bookmarks: 42100,
      gradient: [Color(0xFFE8DFFF), Color(0xFFA39ADB)],
      isSpotlight: true,
    ),
    Artwork(
      id: 'summer-lane',
      title: 'Summer lane',
      artist: 'ren',
      bookmarks: 18200,
      gradient: [Color(0xFFFFE5C9), Color(0xFFC68A5E)],
    ),
    Artwork(
      id: 'green-room',
      title: 'Green room',
      artist: 'toa',
      bookmarks: 13700,
      gradient: [Color(0xFFD6EFE3), Color(0xFF669D81)],
    ),
    Artwork(
      id: 'mirror-cloud',
      title: 'Mirror cloud',
      artist: 'suzu',
      bookmarks: 9800,
      gradient: [Color(0xFFD5E8F5), Color(0xFF7494B5)],
    ),
    Artwork(
      id: 'soft-echo',
      title: 'Soft echo',
      artist: 'nana',
      bookmarks: 25100,
      gradient: [Color(0xFFFFE2E8), Color(0xFFB8717F)],
    ),
  ];
}
