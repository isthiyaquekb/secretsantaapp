import 'package:flutter/material.dart';

enum ExchangeWindow { anyDecember, lastTwoWeeks, weekBeforeChristmas }

/// Change this one line to switch the rule.
const kExchangeWindow = ExchangeWindow.lastTwoWeeks;
const kWeekdaysOnly = false; // true = office days only (Mon-Fri)

DateTimeRange exchangeRange(int year, ExchangeWindow w) {
  switch (w) {
    case ExchangeWindow.anyDecember:
      return DateTimeRange(start: DateTime(year, 12, 1), end: DateTime(year, 12, 31));
    case ExchangeWindow.lastTwoWeeks:
      return DateTimeRange(start: DateTime(year, 12, 18), end: DateTime(year, 12, 31));
    case ExchangeWindow.weekBeforeChristmas:
      return DateTimeRange(start: DateTime(year, 12, 18), end: DateTime(year, 12, 24));
  }
}

bool _ok(DateTime d) => !kWeekdaysOnly || d.weekday <= DateTime.friday;

DateTime defaultExchangeDate(
  int year, {
  ExchangeWindow window = kExchangeWindow,
  bool weekdaysOnly = kWeekdaysOnly,
}) {
  final r = exchangeRange(year, window);
  var d = DateTime(year, 12, 20);
  if (d.isBefore(r.start)) d = r.start;
  if (d.isAfter(r.end)) d = r.end;
  bool isDateOk(DateTime date) =>
      !weekdaysOnly || date.weekday <= DateTime.friday;
  while (!isDateOk(d) && d.isBefore(r.end)) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

Future<DateTime?> pickExchangeDate(BuildContext context,
    {required int year, DateTime? current}) {
  final r = exchangeRange(year, kExchangeWindow);
  var initial = current ?? defaultExchangeDate(year);
  if (initial.isBefore(r.start) || initial.isAfter(r.end)) {
    initial = defaultExchangeDate(year);
  }
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: r.start,
    lastDate: r.end,
    helpText: 'Exchange date',
    selectableDayPredicate: _ok,
  );
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
String formatShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
