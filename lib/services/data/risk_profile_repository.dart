import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/risk_profile.dart';
import '../firebase/risk_profile_service.dart';
import '../firebase/auth_service.dart';

final riskProfileRepositoryProvider = Provider<RiskProfileRepository>((ref) {
  final service = ref.read(riskProfileServiceProvider);
  final auth = ref.read(authServiceProvider);
  return RiskProfileRepository(service, auth);
});

class RiskProfileRepository {
  final RiskProfileService _service;
  final AuthService _auth;

  RiskProfileRepository(this._service, this._auth);

  Future<RiskProfile> fetchRiskProfile() async {
    final uid = _auth.currentUserId;
    if (uid == null) return RiskProfile.defaultProfile;

    final profile = await _service.fetchRiskProfile(uid);
    return profile ?? RiskProfile.defaultProfile;
  }

  Future<void> saveRiskProfile(RiskProfile profile) async {
    final uid = _auth.currentUserId;
    if (uid == null) throw Exception("User not logged in.");

    await _service.saveRiskProfile(uid: uid, profile: profile);
  }
}
