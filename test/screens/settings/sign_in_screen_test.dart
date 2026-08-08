import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riskform/screens/settings/sign_in_screen.dart';
import 'package:riskform/services/firebase/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

Future<void> _pumpSignIn(WidgetTester tester, AuthService authService) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(authService)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authService = AuthService(mockAuth);
  });

  testWidgets('toggling mode changes the submit button label', (
    tester,
  ) async {
    await _pumpSignIn(tester, authService);

    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);

    await tester.tap(find.text('Create Account').first);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(ElevatedButton, 'Create Account'),
      findsOneWidget,
    );
  });

  testWidgets('submitting empty fields shows a validation error', (
    tester,
  ) async {
    await _pumpSignIn(tester, authService);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an email and password.'), findsOneWidget);
    verifyNever(
      () => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('successful sign in calls FirebaseAuth and pops the screen', (
    tester,
  ) async {
    when(
      () => mockAuth.signInWithEmailAndPassword(
        email: 'trader@example.com',
        password: 'hunter2',
      ),
    ).thenAnswer((_) async => MockUserCredential());

    await _pumpSignIn(tester, authService);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'trader@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'hunter2',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    verify(
      () => mockAuth.signInWithEmailAndPassword(
        email: 'trader@example.com',
        password: 'hunter2',
      ),
    ).called(1);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('failed sign in renders the mapped error message', (
    tester,
  ) async {
    when(
      () => mockAuth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    await _pumpSignIn(tester, authService);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'trader@example.com',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'bad');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect password'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
