import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/models/position.dart';
import 'package:riskform/services/data/position_repository.dart';
import 'package:riskform/services/engines/capital_allocation_engine.dart';
import 'package:riskform/services/engines/position_allocation_mapper.dart';
import 'package:riskform/services/firebase/auth_service.dart';
import 'package:riskform/services/firebase/position_service.dart';

class _SignedInAuth extends AuthService {
  _SignedInAuth() : super.noop();

  @override
  String? get currentUserId => 'user-1';
}

Position _put({
  String symbol = 'AAPL',
  double? strike = 50,
  double? premium = 1.0,
  int? contracts = 2,
  bool isOpen = true,
  DateTime? openedAt,
  PositionType type = PositionType.csp,
}) => Position(
  type: type,
  symbol: symbol,
  strategy: 'CSP',
  quantity: 0,
  isOpen: isOpen,
  expiration: DateTime.now().add(const Duration(days: 10, hours: 1)),
  strike: strike,
  premium: premium,
  contracts: contracts,
  openedAt: openedAt,
);

void main() {
  group('Position model', () {
    test('derives capital and premium from strike, premium and contracts', () {
      final p = _put();
      expect(p.capitalLocked, 10000);
      expect(p.totalPremium, 200);
    });

    test('returns null capital when data is missing or for shares', () {
      expect(_put(strike: null).capitalLocked, isNull);
      expect(_put(contracts: null).capitalLocked, isNull);
      expect(_put(contracts: 0).capitalLocked, isNull);
      expect(_put(premium: null).totalPremium, isNull);
      expect(_put(type: PositionType.shares).capitalLocked, isNull);
    });

    test('round-trips the new fields through JSON', () {
      final opened = DateTime.utc(2026, 11, 1, 14);
      final restored = Position.fromJson({
        ..._put(openedAt: opened).toJson(),
        'id': 'abc',
      });

      expect(restored.id, 'abc');
      expect(restored.strike, 50);
      expect(restored.premium, 1.0);
      expect(restored.contracts, 2);
      expect(restored.openedAt, opened);
    });

    test('reads positions saved before the new fields existed', () {
      final legacy = Position.fromJson({
        'type': 'csp',
        'symbol': 'F',
        'strategy': 'CSP',
        'quantity': 1,
        'isOpen': true,
        'expiration': DateTime(2026, 12, 1).toIso8601String(),
      });

      expect(legacy.strike, isNull);
      expect(legacy.contracts, isNull);
      expect(legacy.openedAt, isNull);
      expect(legacy.capitalLocked, isNull);
    });

    test('does not store the id or unset fields', () {
      final json = _put(strike: null, premium: null, contracts: null).toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('strike'), isFalse);
      expect(json.containsKey('contracts'), isFalse);
    });
  });

  group('holdingsFromPositions', () {
    test('converts complete open positions', () {
      final opened = DateTime.now().subtract(const Duration(days: 20));
      final result = holdingsFromPositions([_put(openedAt: opened)]);

      expect(result.skipped, 0);
      final h = result.holdings.single;
      expect(h.symbol, 'AAPL');
      expect(h.strategy, HoldingStrategy.csp);
      expect(h.capital, 10000);
      expect(h.premium, 200);
      expect(h.dte, 10);
      expect(h.originalDays, 30);
    });

    test('falls back to remaining days when the open date is unknown', () {
      final h = holdingsFromPositions([_put()]).holdings.single;
      expect(h.originalDays, h.dte);
    });

    test('skips closed positions silently and counts incomplete ones', () {
      final result = holdingsFromPositions([
        _put(isOpen: false),
        _put(strike: null),
        _put(type: PositionType.shares),
        _put(symbol: 'KO'),
      ]);

      expect(result.holdings.map((h) => h.symbol), ['KO']);
      expect(result.skipped, 2);
    });

    test('maps covered calls', () {
      final h = holdingsFromPositions([
        _put(type: PositionType.coveredCall),
      ]).holdings.single;
      expect(h.strategy, HoldingStrategy.coveredCall);
    });
  });

  group('saving and streaming positions', () {
    late FakeFirebaseFirestore db;
    late PositionRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = PositionRepository(PositionService(db), _SignedInAuth());
    });

    test('saves under the signed-in user and reads the fields back', () async {
      await repo.save(_put());

      final docs = await db
          .collection('users')
          .doc('user-1')
          .collection('positions')
          .get();
      expect(docs.docs.length, 1);
      expect(docs.docs.single.data()['strike'], 50);

      final listed = await repo.listAll();
      expect(listed.single.id, docs.docs.single.id);
      expect(listed.single.capitalLocked, 10000);
    });

    test('keeps two puts on the same symbol and expiration separate', () async {
      final expiration = DateTime.now().add(const Duration(days: 30));
      Position at(double strike) =>
          _put(strike: strike).copyWith(expiration: expiration);

      await repo.save(at(50));
      await repo.save(at(55));

      final listed = await repo.listAll();
      expect(listed.map((p) => p.strike).toSet(), {50.0, 55.0});
    });

    test('closing a position removes it from the open set', () async {
      await repo.save(_put(symbol: 'AAPL'));
      await repo.save(_put(symbol: 'KO'));
      final aapl = (await repo.listAll()).firstWhere((p) => p.symbol == 'AAPL');

      await repo.close(aapl.id!);

      final open = (await repo.listAll()).where((p) => p.isOpen).toList();
      expect(open.map((p) => p.symbol), ['KO']);
    });

    test('streams positions as they change', () async {
      final emissions = <int>[];
      final sub = repo.stream().listen((l) => emissions.add(l.length));

      await repo.save(_put());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(emissions.last, 1);
    });
  });
}
