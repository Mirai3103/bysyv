import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchRecentStoreProvider = Provider<SearchRecentStore>((ref) {
  return SearchRecentStore();
});

class SearchRecentStore {
  static const recentLimit = 5;
  static const _key = 'search_recent_words_v1';

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _normalize(prefs.getStringList(_key) ?? const []);
  }

  Future<List<String>> saveWord(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return load();

    final current = await load();
    final next = [
      trimmed,
      for (final item in current)
        if (item != trimmed) item,
    ].take(recentLimit).toList();
    await _save(next);
    return next;
  }

  Future<List<String>> remove(String word) async {
    final current = await load();
    final next = current.where((item) => item != word).toList();
    await _save(next);
    return next;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<String> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _normalize(words));
  }

  List<String> _normalize(List<String> words) {
    final unique = <String>[];
    for (final word in words) {
      final trimmed = word.trim();
      if (trimmed.isEmpty || unique.contains(trimmed)) continue;
      unique.add(trimmed);
      if (unique.length == recentLimit) break;
    }
    return unique;
  }
}
