import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riskform/services/firebase/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  test('signOut calls FirebaseAuth.signOut', () async {
    final mock = MockFirebaseAuth();
    when(() => mock.signOut()).thenAnswer((_) async {});

    final svc = AuthService(mock);
    await svc.signOut();

    verify(() => mock.signOut()).called(1);
  });

  test('sendPasswordResetEmail maps network error', () async {
    final mock = MockFirebaseAuth();
    when(() => mock.sendPasswordResetEmail(email: any(named: 'email'))).thenThrow(
      FirebaseAuthException(code: 'network-request-failed', message: 'network'),
    );

    final svc = AuthService(mock);

    expect(
      () => svc.sendPasswordResetEmail('a@b.com'),
      throwsA(predicate((e) => e.toString().contains('Network error'))),
    );
  });
}
