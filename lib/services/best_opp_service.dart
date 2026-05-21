import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/best_opp_model.dart';

class BestOppService {
  final FirebaseFirestore _db;

  BestOppService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference _col(String userId) =>
      _db.collection('users').doc(userId).collection('bestOpps');

  /// Fetch opps for a single [date] string (yyyy-MM-dd).
  Future<List<BestOppModel>> listByDate(String userId, String date) async {
    final snap = await _col(userId)
        .where('date', isEqualTo: date)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(BestOppModel.fromFirestore).toList();
  }

  /// Fetch all opps for the user across all dates.
  Future<List<BestOppModel>> listAll(String userId) async {
    final snap = await _col(
      userId,
    ).orderBy('createdAt', descending: true).limit(200).get();
    return snap.docs.map(BestOppModel.fromFirestore).toList();
  }

  /// Create a new opp and return it with the generated [id].
  Future<BestOppModel> create({
    required String userId,
    required String date,
    required String ticker,
    required String setup,
    required String entryTrigger,
    required String whatMadeItIdeal,
    required bool wasTaken,
    String? screenshotUrl,
    String? notes,
  }) async {
    final ref = _col(userId).doc();
    final opp = BestOppModel(
      id: ref.id,
      userId: userId,
      date: date,
      ticker: ticker.toUpperCase(),
      setup: setup,
      entryTrigger: entryTrigger,
      whatMadeItIdeal: whatMadeItIdeal,
      wasTaken: wasTaken,
      screenshotUrl: screenshotUrl,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await ref.set(opp.toFirestore());
    return opp;
  }

  /// Toggle the [wasTaken] flag on an existing opp.
  Future<void> toggleTaken(String userId, String oppId, bool wasTaken) async {
    await _col(userId).doc(oppId).update({'wasTaken': wasTaken});
  }

  Future<void> delete(String userId, String oppId) async {
    await _col(userId).doc(oppId).delete();
  }
}
