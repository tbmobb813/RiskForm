import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/journal/discipline_scoring_service.dart';

final disciplineScoringProvider = Provider<DisciplineScoringService>((ref) {
  return DisciplineScoringService();
});
