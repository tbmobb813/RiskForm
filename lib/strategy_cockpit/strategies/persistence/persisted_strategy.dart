class PersistedStrategy {
  final String type;
  final Map<String, dynamic> data;

  PersistedStrategy({required this.type, required this.data});

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
      };

  static PersistedStrategy fromJson(Map<String, dynamic> json) {
    return PersistedStrategy(
      type: json['type'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}
