import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_context.dart';
import '../services/data/account_repository.dart';

final accountContextProvider = FutureProvider<AccountContext>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  final account = await repo.fetchAccount();
  if (account == null) {
    return const AccountContext(accountSize: 0, buyingPower: 0);
  }

  return AccountContext(
    accountSize: account.accountSize,
    buyingPower: account.buyingPower,
  );
});