class StrategyMetadata {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> params;

  StrategyMetadata({
    required this.id,
    required this.name,
    required this.description,
    this.params = const {},
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'params': params,
      };

  factory StrategyMetadata.fromMap(Map<String, dynamic> m) => StrategyMetadata(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String,
        params: Map<String, dynamic>.from(m['params'] as Map? ?? {}),
      );
}
