import 'package:cloud_firestore/cloud_firestore.dart';

/// Common options strategy setups used as tags on a Best Opp.
const kOppSetups = [
  'Wheel / CSP',
  'Covered Call',
  'PMCC',
  'Debit Spread',
  'Credit Spread',
  'Iron Condor',
  'Calendar Spread',
  'Long Call',
  'Long Put',
  'Straddle / Strangle',
  '0DTE Play',
  'Stock / Shares',
  'Other',
];

class BestOppModel {
  final String id;
  final String userId;
  final String date; // yyyy-MM-dd — primary filter key
  final String ticker;
  final String setup; // strategy tag from kOppSetups
  final String entryTrigger;
  final String whatMadeItIdeal;
  final bool wasTaken;
  final String? screenshotUrl;
  final String? notes;
  final DateTime createdAt;

  const BestOppModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.ticker,
    required this.setup,
    required this.entryTrigger,
    required this.whatMadeItIdeal,
    required this.wasTaken,
    this.screenshotUrl,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'date': date,
    'ticker': ticker,
    'setup': setup,
    'entryTrigger': entryTrigger,
    'whatMadeItIdeal': whatMadeItIdeal,
    'wasTaken': wasTaken,
    'screenshotUrl': screenshotUrl,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static BestOppModel fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return BestOppModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      date: d['date'] as String? ?? '',
      ticker: d['ticker'] as String? ?? '',
      setup: d['setup'] as String? ?? 'Other',
      entryTrigger: d['entryTrigger'] as String? ?? '',
      whatMadeItIdeal: d['whatMadeItIdeal'] as String? ?? '',
      wasTaken: d['wasTaken'] as bool? ?? false,
      screenshotUrl: d['screenshotUrl'] as String?,
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  BestOppModel copyWith({bool? wasTaken}) => BestOppModel(
    id: id,
    userId: userId,
    date: date,
    ticker: ticker,
    setup: setup,
    entryTrigger: entryTrigger,
    whatMadeItIdeal: whatMadeItIdeal,
    wasTaken: wasTaken ?? this.wasTaken,
    screenshotUrl: screenshotUrl,
    notes: notes,
    createdAt: createdAt,
  );
}
