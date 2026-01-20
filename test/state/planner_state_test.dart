import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/state/planner_state.dart';

void main() {
  test('PlannerState copyWith and clearError behavior', () {
    final s = PlannerState.initial().copyWith(isLoading: false, errorMessage: 'err');
    final cleared = s.copyWith(clearError: true);

    expect(s.errorMessage, 'err');
    expect(cleared.errorMessage, isNull);

    final updated = s.copyWith(strategyId: 'x', notes: 'n');
    expect(updated.strategyId, 'x');
    expect(updated.notes, 'n');
  });
}
