class Account {
  Account({required this.id, required this.name, required this.type});

  final int id;
  final String name;
  final String type;

  factory Account.fromMap(Map<String, Object?> map) {
    return Account(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type,
      };
}
