import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riskform/state/account_context_provider.dart';
import 'package:riskform/services/data/account_repository.dart';
import 'package:riskform/models/account_context.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  test('accountContextProvider returns defaults when repo null', () async {
    final repo = MockAccountRepository();
    final container = ProviderContainer(overrides: [
      accountRepositoryProvider.overrideWithValue(repo),
    ]);

    when(() => repo.fetchAccount()).thenAnswer((_) async => null);

    final result = await container.read(accountContextProvider.future);
    expect(result, isA<AccountContext>());
    expect(result.accountSize, 0);
  });
}
