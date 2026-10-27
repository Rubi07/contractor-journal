class DraftEntry {
  DraftEntry({
    required this.date,
    required this.project,
    required this.debitAcc,
    required this.creditAcc,
    required this.amount,
    this.partyId,
    required this.note,
  });

  String date;
  String project;
  String debitAcc;
  String creditAcc;
  double amount;
  int? partyId;
  String note;
}

class BengaliJournalParser {
  static DraftEntry parse(String transcript, {DateTime? now}) {
    final current = now ?? DateTime.now();
    String date;
    if (transcript.contains('গতকাল')) {
      final yesterday = current.subtract(const Duration(days: 1));
      date = _formatDate(yesterday);
    } else {
      date = _formatDate(current);
    }

    if (transcript.contains('দান')) {
      return DraftEntry(
        date: date,
        project: 'General',
        debitAcc: 'Donation',
        creditAcc: 'Cash',
        amount: _extractAmount(transcript),
        note: transcript.trim(),
      );
    }

    String project = 'General';
    if (transcript.contains('A প্রকল্প')) {
      project = 'A Project';
    } else if (transcript.contains('B কাজ')) {
      project = 'B Work';
    }

    final account = _extractAccount(transcript);
    return DraftEntry(
      date: date,
      project: project,
      debitAcc: account,
      creditAcc: 'Cash',
      amount: _extractAmount(transcript),
      note: transcript.trim(),
    );
  }

  static String normalizeDigits(String text) {
    const bengaliDigits = '০১২৩৪৫৬৭৮৯';
    var normalized = text;
    for (var index = 0; index < bengaliDigits.length; index++) {
      normalized = normalized.replaceAll(bengaliDigits[index], '$index');
    }
    return normalized;
  }

  static double _extractAmount(String transcript) {
    final normalized = normalizeDigits(transcript);
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(normalized);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
  }

  static String _extractAccount(String transcript) {
    const keywordAccounts = <String, String>{
      'লেবার': 'Direct Labor',
      'মজুরি': 'Direct Labor',
      'সাব-কন্ট্রাক্টর': 'Subcontractor',
      'গাড়ি ভাড়া': 'Equipment Rental',
      'JCB ভাড়া': 'Equipment Rental',
      'মালামাল': 'Materials',
      'সিমেন্ট': 'Materials',
      'রড': 'Materials',
      'পরিবহন': 'Transport',
      'টানলাম': 'Transport',
      'জ্বালানি': 'Fuel',
      'ডিজেল': 'Fuel',
      'অফিস': 'Office',
      'বিমা': 'Insurance',
    };

    for (final entry in keywordAccounts.entries) {
      if (transcript.contains(entry.key)) return entry.value;
    }
    return 'Direct Labor';
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
