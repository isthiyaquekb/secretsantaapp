import 'package:flutter_test/flutter_test.dart';
import 'package:xmasfriend/core/utils/exchange_date.dart';

void main() {
  group('Exchange Date Unit Tests', () {
    test('Range for each of the three windows', () {
      const year = 2026;

      // anyDecember: Dec 1 - Dec 31
      final anyDec = exchangeRange(year, ExchangeWindow.anyDecember);
      expect(anyDec.start, equals(DateTime(2026, 12, 1)));
      expect(anyDec.end, equals(DateTime(2026, 12, 31)));

      // lastTwoWeeks: Dec 18 - Dec 31
      final lastTwo = exchangeRange(year, ExchangeWindow.lastTwoWeeks);
      expect(lastTwo.start, equals(DateTime(2026, 12, 18)));
      expect(lastTwo.end, equals(DateTime(2026, 12, 31)));

      // weekBeforeChristmas: Dec 18 - Dec 24
      final weekBefore =
          exchangeRange(year, ExchangeWindow.weekBeforeChristmas);
      expect(weekBefore.start, equals(DateTime(2026, 12, 18)));
      expect(weekBefore.end, equals(DateTime(2026, 12, 24)));
    });

    test('defaultExchangeDate always falls inside the window', () {
      for (final window in ExchangeWindow.values) {
        for (int year = 2024; year <= 2030; year++) {
          final range = exchangeRange(year, window);
          final defaultDate = defaultExchangeDate(year, window: window);

          expect(
            defaultDate.isBefore(range.start),
            isFalse,
            reason:
                'Date $defaultDate should not be before range start ${range.start} for $window ($year)',
          );
          expect(
            defaultDate.isAfter(range.end),
            isFalse,
            reason:
                'Date $defaultDate should not be after range end ${range.end} for $window ($year)',
          );
        }
      }
    });

    test('with kWeekdaysOnly=true it never returns a weekend', () {
      for (final window in ExchangeWindow.values) {
        for (int year = 2024; year <= 2035; year++) {
          final date = defaultExchangeDate(
            year,
            window: window,
            weekdaysOnly: true,
          );

          expect(
            date.weekday,
            isNot(anyOf(DateTime.saturday, DateTime.sunday)),
            reason:
                'Date $date for year $year in $window was a weekend (${date.weekday})',
          );
        }
      }
    });

    test('formatShortDate formats correctly', () {
      expect(formatShortDate(DateTime(2026, 12, 20)), equals('Dec 20'));
      expect(formatShortDate(DateTime(2026, 1, 5)), equals('Jan 5'));
      expect(formatShortDate(DateTime(2026, 11, 28)), equals('Nov 28'));
    });
  });
}

