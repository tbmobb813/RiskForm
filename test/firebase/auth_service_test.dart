import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riskform/services/firebase/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  setUpAll(() {
  });

  test('requireAuth throws when no user', () {
    final mock = MockFirebaseAuth();
    when(() => mock.currentUser).thenReturn(null);

    final svc = AuthService(mock);

    expect(() => svc.requireAuth(), throwsA(isA<Exception>()));
  });

  test('requireAuth returns uid when user present', () {
    final mock = MockFirebaseAuth();
    final user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => mock.currentUser).thenReturn(user);

    final svc = AuthService(mock);

    expect(svc.requireAuth(), 'u1');
  });
}
