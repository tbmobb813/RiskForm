import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/screens/cockpit/controllers/cockpit_controller.dart';
import 'package:riskform/screens/cockpit/services/cockpit_data_client.dart';
import 'package:riskform/models/position.dart';
import 'package:riskform/state/account_providers.dart';

// Fake data client that returns deterministic test data
class FakeCockpitDataClient implements CockpitDataClient {
  @override
  Future<List<String>> fetchWatchlist(String uid) async {
    return ['SPY', 'AAPL'];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingJournals(String uid) async {
    return [
      {
        'positionId': 'p1',
        'ticker': 'AAPL',
        'strategy': 'CSP AAPL',
        'pnl': 10.5,
        'closedAt': DateTime.now().toIso8601String(),
        'isPaper': true,
      }
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecentJournals(String uid) async {
    return [
      {
        'disciplineScore': 85,
        'disciplineBreakdown': {'adherence': 35}
      },
      {
        'disciplineScore': 90,
        'disciplineBreakdown': {'adherence': 37}
      }
    ];
  }

  @override
  Future<List<Position>> fetchOpenPositions(String uid) async {
    return [
      Position(
        type: PositionType.csp,
        symbol: 'AAPL',
        strategy: 'CSP',
        quantity: 1,
        expiration: DateTime.now().add(const Duration(days: 30)),
        isOpen: true,
      )
    ];
  }
}

// Minimal fake Ref that only responds to account providers used by CockpitController
class FakeRef {
  T read<T>(dynamic provider) {
    if (provider == accountBalanceProvider) return 1000.0 as T;
    if (provider == riskDeployedProvider) return 100.0 as T;
    throw Exception('Unexpected provider read in FakeRef: $provider');
  }
}

void main() {
  test('CockpitController.refresh loads data from data client', () async {
    final fakeRef = FakeRef();
    final fakeClient = FakeCockpitDataClient();

    final controller = CockpitController(fakeRef, dataClient: fakeClient, getUid: () => 'test-uid');

    // Initial state isLoading true by default
    expect(controller.state.isLoading, true);

    await controller.refresh();

    final s = controller.state;

    expect(s.isLoading, false);
    expect(s.watchlist.map((w) => w.ticker).toList(), ['SPY', 'AAPL']);
    expect(s.pendingJournals.length, 1);
    expect(s.positions.length, 1);
    expect(s.discipline.currentScore, (85 + 90) ~/ 2);
    expect(s.account.balance, 1000.0);
    expect(s.account.riskDeployed, 100.0);
  });
}
