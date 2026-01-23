import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/execution/execution_service.dart';
import 'package:riskform/planner/models/planner_strategy_context.dart';

void main() {
  test('ExecutionService rejects requests missing userId', () async {
    final svc = ExecutionService();

    final ctx = PlannerStrategyContext(
      strategyId: 's1',
      strategyName: 'S1',
      state: 'active',
      tags: [],
      constraintsSummary: null,
      constraints: {},
      currentRegime: null,
      disciplineFlags: [],
      updatedAt: DateTime.now(),
    );

    final req = StrategyExecutionRequest(strategyContext: ctx, execution: {});

    final res = await svc.executeStrategyTrade(req);
    expect(res.success, isFalse);
    expect(res.errorMessage, 'Authentication required: missing userId in execution payload.');
  });
}
