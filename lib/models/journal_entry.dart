class JournalEntry {
  JournalEntry({
    required this.id,
    required this.date,
    required this.projectId,
    required this.debitAccountId,
    required this.creditAccountId,
    required this.amount,
    required this.note,
    this.partyId,
    required this.createdAt,
  });

  final int id;
  final String date;
  final int projectId;
  final int debitAccountId;
  final int creditAccountId;
  final double amount;
  final String note;
  final int? partyId;
  final String createdAt;

  factory JournalEntry.fromMap(Map<String, Object?> map) {
    return JournalEntry(
      id: map['id'] as int,
      date: map['date'] as String,
      projectId: map['project_id'] as int,
      debitAccountId: map['debit_acc'] as int,
      creditAccountId: map['credit_acc'] as int,
      amount: (map['amount'] as num).toDouble(),
      note: (map['note'] as String?) ?? '',
      partyId: map['party_id'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date,
        'project_id': projectId,
        'debit_acc': debitAccountId,
        'credit_acc': creditAccountId,
        'amount': amount,
        'note': note,
        'party_id': partyId,
        'created_at': createdAt,
      };
}
