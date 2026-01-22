import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riskform/services/firebase/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  test('signInWithEmail maps user-not-found to AuthenticationException', () async {
    final mock = MockFirebaseAuth();
    when(() => mock.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'no user'));

    final svc = AuthService(mock);

    expect(
      () => svc.signInWithEmail(email: 'x', password: 'y'),
      throwsA(predicate((e) => e is Exception && e.toString().contains('No account found'))),
    );
  });

  test('signUpWithEmail maps email-already-in-use to AuthenticationException', () async {
    final mock = MockFirebaseAuth();
    when(() => mock.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(FirebaseAuthException(code: 'email-already-in-use', message: 'exists'));

    final svc = AuthService(mock);

    expect(
      () => svc.signUpWithEmail(email: 'x', password: 'y'),
      throwsA(predicate((e) => e is Exception && e.toString().contains('An account already exists'))),
    );
  });
}
