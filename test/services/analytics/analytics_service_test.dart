import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/analytics/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('log is a silent no-op when Firebase is not initialized', () async {
    await expectLater(
      AnalyticsService.log(AnalyticsEvents.simRun, {'source': 'test'}),
      completes,
    );
  });

  test('logSignUp is a silent no-op when Firebase is not initialized', () async {
    await expectLater(AnalyticsService.logSignUp(), completes);
  });
}
