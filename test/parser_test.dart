import 'package:contractor_journal/parser/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime(2026, 10, 27, 12);

  test('বাঙলা সংখ্যাকে parse করে এবং লেবার project বের করে', () {
    final draft = BengaliJournalParser.parse(
      'গতকাল A প্রকল্প লেবার ১২৫০ টাকা',
      now: fixedNow,
    );

    expect(draft.amount, 1250);
    expect(draft.project, 'A Project');
    expect(draft.debitAcc, 'Direct Labor');
    expect(draft.creditAcc, 'Cash');
    expect(draft.date, '2026-10-26');
  });

  test('দান সর্বদা General এবং Donation হবে', () {
    final draft = BengaliJournalParser.parse(
      'A প্রকল্প দান ৫০০ টাকা LEBAR অফিস',
      now: fixedNow,
    );

    expect(draft.project, 'General');
    expect(draft.debitAcc, 'Donation');
    expect(draft.amount, 500);
  });

  test('জালালি এবং ইংরেজি project/number চিনে', () {
    final draft = BengaliJournalParser.parse(
      'আজ B কাজ ডিজেল 750 টাকা',
      now: fixedNow,
    );

    expect(draft.date, '2026-10-27');
    expect(draft.project, 'B Work');
    expect(draft.debitAcc, 'Fuel');
    expect(draft.amount, 750);
  });
}
