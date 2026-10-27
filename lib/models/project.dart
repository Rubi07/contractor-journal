class Project {
  Project({required this.id, required this.name});

  final int id;
  final String name;

  factory Project.fromMap(Map<String, Object?> map) {
    return Project(id: map['id'] as int, name: map['name'] as String);
  }

  Map<String, Object?> toMap() => {'id': id, 'name': name};
}
