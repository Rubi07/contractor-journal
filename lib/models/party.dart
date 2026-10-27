class Party {
  final int id;
  final String name;
  final String type; // 'customer' | 'supplier'

  Party({required this.id, required this.name, required this.type});

  factory Party.fromMap(Map<String, Object?> map) {
    return Party(
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
