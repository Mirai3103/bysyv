import 'package:bysiv/data/repositories/search_recent_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SearchRecentStore', () {
    test(
      'normalizes, de-duplicates, limits, removes, and clears words',
      () async {
        SharedPreferences.setMockInitialValues({
          'search_recent_words_v1': ['  miku  ', '', 'rin', 'miku'],
        });
        final store = SearchRecentStore();

        expect(await store.load(), ['miku', 'rin']);
        expect(await store.saveWord(' luka '), ['luka', 'miku', 'rin']);
        await store.saveWord('one');
        await store.saveWord('two');
        await store.saveWord('three');
        expect(await store.saveWord('four'), [
          'four',
          'three',
          'two',
          'one',
          'luka',
        ]);
        expect(await store.remove('two'), ['four', 'three', 'one', 'luka']);
        await store.clear();
        expect(await store.load(), isEmpty);
      },
    );
  });
}
