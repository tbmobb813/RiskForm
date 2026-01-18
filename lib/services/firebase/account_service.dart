import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';

final accountServiceProvider = Provider<AccountService>((ref) => AccountService());

class AccountService {
  final FirebaseFirestore _db;

  AccountService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Future<Account?> fetchAccount(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || !data.containsKey('account')) return null;

    final acct = data['account'];
    if (acct is Map<String, dynamic>) {
      return Account.fromJson(Map<String, dynamic>.from(acct));
    }

    return null;
  }
}

