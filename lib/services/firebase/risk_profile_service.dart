import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/risk_profile.dart';

final riskProfileServiceProvider = Provider<RiskProfileService>((ref) => RiskProfileService());

class RiskProfileService {
  final FirebaseFirestore _db;

  RiskProfileService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Future<RiskProfile?> fetchRiskProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || !data.containsKey('riskProfile')) return null;

    final profile = data['riskProfile'];
    if (profile is Map<String, dynamic>) {
      return RiskProfile.fromJson(Map<String, dynamic>.from(profile));
    }

    return null;
  }

  Future<void> saveRiskProfile({
    required String uid,
    required RiskProfile profile,
  }) async {
    await _db.collection('users').doc(uid).set(
      {'riskProfile': profile.toJson()},
      SetOptions(merge: true),
    );
  }
}
