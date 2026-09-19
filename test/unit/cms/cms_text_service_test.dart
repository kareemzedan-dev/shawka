import 'package:flutter_test/flutter_test.dart';
import 'package:matlobgo/core/cms/cms_keys.dart';
import 'package:matlobgo/core/cms/cms_text_format.dart';
import 'package:matlobgo/models/cms_text_entry.dart';

void main() {
  group('interpolateCmsTemplate', () {
    test('replaces {name}, {city} and {time}', () {
      expect(
        interpolateCmsTemplate(
          'أهلاً {name} من {city} — الساعة {time}',
          name: 'أحمد',
          city: 'القاهرة',
          time: '09:30',
        ),
        'أهلاً أحمد من القاهرة — الساعة 09:30',
      );
    });

    test('missing values become empty strings', () {
      expect(interpolateCmsTemplate('مرحباً {name}{city}{time}'), 'مرحباً ');
    });

    test('replaces repeated placeholders', () {
      expect(
        interpolateCmsTemplate('{name} و {name}', name: 'سارة'),
        'سارة و سارة',
      );
    });

    test('leaves templates without placeholders untouched', () {
      expect(interpolateCmsTemplate('صباح الخير', name: 'x'), 'صباح الخير');
    });
  });

  group('parseCmsPipeList (blacklist parsing)', () {
    test('splits on pipe and trims entries', () {
      expect(
        parseCmsPipeList(' كلمة | أخرى |ثالثة'),
        ['كلمة', 'أخرى', 'ثالثة'],
      );
    });

    test('drops empty segments', () {
      expect(parseCmsPipeList('a||b| |c'), ['a', 'b', 'c']);
    });

    test('returns fallback for empty or whitespace-only input', () {
      expect(parseCmsPipeList('', fallback: ['x']), ['x']);
      expect(parseCmsPipeList(' | | ', fallback: ['x']), ['x']);
    });
  });

  group('CmsTextDefaults', () {
    test('contains greeting and search keys', () {
      final keys = CmsTextDefaults.entries.map((e) => e.$1).toSet();
      expect(
        keys,
        containsAll(<String>{
          CmsKeys.greetingMorning,
          CmsKeys.greetingEvening,
          CmsKeys.greetingGuestHeadline,
          CmsKeys.greetingSeasonal,
          CmsKeys.searchSuggestions,
          CmsKeys.searchTrending,
          CmsKeys.searchBlacklist,
          CmsKeys.searchPlaceholder,
        }),
      );
    });

    test('has no duplicate keys', () {
      final keys = CmsTextDefaults.entries.map((e) => e.$1).toList();
      expect(keys.toSet().length, keys.length);
    });
  });
}
