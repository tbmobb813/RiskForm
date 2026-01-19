class DisciplineScore {
  final int total;
  final int adherence;
  final int timing;
  final int risk;

  DisciplineScore({
    required this.total,
    required this.adherence,
    required this.timing,
    required this.risk,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'total': total,
      'adherence': adherence,
      'timing': timing,
      'risk': risk,
    };
  }
}
