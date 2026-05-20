import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/best_opp_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late BestOppService service;
  const uid = 'user_test_123';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = BestOppService(firestore: fakeDb);
  });

  // ── create ────────────────────────────────────────────────────────────────
  group('create', () {
    test('returns a BestOppModel with a generated id', () async {
      final opp = await service.create(
        userId: uid,
        date: '2024-01-19',
        ticker: 'aapl', // should be uppercased
        setup: 'Wheel / CSP',
        entryTrigger: 'Break above VWAP',
        whatMadeItIdeal: 'IV rank 72, clean setup',
        wasTaken: true,
      );

      expect(opp.id, isNotEmpty);
      expect(opp.ticker, 'AAPL'); // uppercased
      expect(opp.wasTaken, isTrue);
      expect(opp.date, '2024-01-19');
      expect(opp.setup, 'Wheel / CSP');
    });

    test('optional fields default to null', () async {
      final opp = await service.create(
        userId: uid,
        date: '2024-01-20',
        ticker: 'NVDA',
        setup: 'Other',
        entryTrigger: 'Breakout',
        whatMadeItIdeal: 'Momentum',
        wasTaken: false,
      );

      expect(opp.screenshotUrl, isNull);
      expect(opp.notes, isNull);
    });
  });

  // ── listByDate ────────────────────────────────────────────────────────────
  group('listByDate', () {
    test('returns only opps matching the given date', () async {
      await service.create(
        userId: uid,
        date: '2024-01-19',
        ticker: 'AAPL',
        setup: 'Wheel / CSP',
        entryTrigger: 'Trigger A',
        whatMadeItIdeal: 'Ideal A',
        wasTaken: true,
      );
      await service.create(
        userId: uid,
        date: '2024-01-20',
        ticker: 'NVDA',
        setup: 'Long Call',
        entryTrigger: 'Trigger B',
        whatMadeItIdeal: 'Ideal B',
        wasTaken: false,
      );

      final opps = await service.listByDate(uid, '2024-01-19');
      expect(opps.length, 1);
      expect(opps.first.ticker, 'AAPL');
    });

    test('returns empty list when no opps on that date', () async {
      final opps = await service.listByDate(uid, '2099-12-31');
      expect(opps, isEmpty);
    });
  });

  // ── listAll ───────────────────────────────────────────────────────────────
  group('listAll', () {
    test('returns all opps across dates', () async {
      for (int i = 1; i <= 3; i++) {
        await service.create(
          userId: uid,
          date: '2024-01-${i.toString().padLeft(2, '0')}',
          ticker: 'SPY',
          setup: 'Credit Spread',
          entryTrigger: 'T$i',
          whatMadeItIdeal: 'I$i',
          wasTaken: i.isOdd,
        );
      }

      final all = await service.listAll(uid);
      expect(all.length, 3);
    });
  });

  // ── toggleTaken ───────────────────────────────────────────────────────────
  group('toggleTaken', () {
    test('updates wasTaken in Firestore', () async {
      final opp = await service.create(
        userId: uid,
        date: '2024-01-19',
        ticker: 'TSLA',
        setup: 'Debit Spread',
        entryTrigger: 'T',
        whatMadeItIdeal: 'I',
        wasTaken: false,
      );

      await service.toggleTaken(uid, opp.id, true);

      final updated = await service.listByDate(uid, '2024-01-19');
      expect(updated.first.wasTaken, isTrue);
    });
  });

  // ── delete ────────────────────────────────────────────────────────────────
  group('delete', () {
    test('removes the opp so it no longer appears in listAll', () async {
      final opp = await service.create(
        userId: uid,
        date: '2024-01-19',
        ticker: 'QQQ',
        setup: 'Other',
        entryTrigger: 'T',
        whatMadeItIdeal: 'I',
        wasTaken: false,
      );

      await service.delete(uid, opp.id);

      final all = await service.listAll(uid);
      expect(all.where((o) => o.id == opp.id), isEmpty);
    });
  });

  // ── fromFirestore roundtrip ───────────────────────────────────────────────
  group('BestOppModel serialization', () {
    test(
      'toFirestore → fromFirestore roundtrip preserves all fields',
      () async {
        final original = await service.create(
          userId: uid,
          date: '2024-03-15',
          ticker: 'AMD',
          setup: 'PMCC',
          entryTrigger: 'Break above 200MA',
          whatMadeItIdeal: 'High IV rank, clean breakout',
          wasTaken: true,
          screenshotUrl: 'https://example.com/chart.png',
          notes: 'Watched this for 3 days',
        );

        final list = await service.listByDate(uid, '2024-03-15');
        expect(list.length, 1);

        final roundtrip = list.first;
        expect(roundtrip.ticker, original.ticker);
        expect(roundtrip.setup, original.setup);
        expect(roundtrip.entryTrigger, original.entryTrigger);
        expect(roundtrip.whatMadeItIdeal, original.whatMadeItIdeal);
        expect(roundtrip.wasTaken, original.wasTaken);
        expect(roundtrip.screenshotUrl, original.screenshotUrl);
        expect(roundtrip.notes, original.notes);
      },
    );
  });
}
