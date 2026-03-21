class Strategy {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Strategy({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Strategy.fromMap(Map<String, dynamic> map) => Strategy(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'name': name,
    'description': description,
  };
}
