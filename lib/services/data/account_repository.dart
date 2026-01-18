import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../firebase/account_service.dart';
import '../firebase/auth_service.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final service = ref.read(accountServiceProvider);
  final auth = ref.read(authServiceProvider);
  return AccountRepository(service, auth);
});

class AccountRepository {
  final AccountService _service;
  final AuthService _auth;

  AccountRepository(this._service, this._auth);

  Future<Account?> fetchAccount() async {
    final uid = _auth.currentUserId;
    if (uid == null) return null;

    return _service.fetchAccount(uid);
  }
}

