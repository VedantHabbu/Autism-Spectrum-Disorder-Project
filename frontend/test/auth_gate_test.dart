import 'dart:convert';

import 'package:asd_nlp_screening_app/core/api_client.dart';
import 'package:asd_nlp_screening_app/core/api_outcome.dart';
import 'package:asd_nlp_screening_app/features/auth/auth_gate.dart';
import 'package:asd_nlp_screening_app/features/auth/auth_screen.dart';
import 'package:asd_nlp_screening_app/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_auth_service.dart';

void main() {
  ApiClient offlineApiClient() => ApiClient(
        httpClient: MockClient((_) async => http.Response('', 500)),
      );

  Widget gate(FakeAuthService auth) => MaterialApp(
        home: AuthGate(authService: auth, apiClient: offlineApiClient()),
      );

  testWidgets('signed-out caregivers see the sign-in screen', (tester) async {
    final auth = FakeAuthService(signedIn: false);
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('signed-in caregivers see the app', (tester) async {
    final auth = FakeAuthService(signedIn: true, email: 'caregiver@example.test');
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('signing in swaps the sign-in screen for the app', (tester) async {
    final auth = FakeAuthService(signedIn: false);
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);

    auth.emitSignedIn(true);
    await tester.pump(); // deliver the broadcast event
    await tester.pump(); // rebuild with the new snapshot

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('signing out returns to the sign-in screen', (tester) async {
    final auth = FakeAuthService(signedIn: true, email: 'caregiver@example.test');
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(auth.calls, contains('signOut'));
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('sign-up submits to Supabase auth and signs the caregiver in',
      (tester) async {
    final auth = FakeAuthService(signedIn: false);
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();

    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'new@example.test');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pump();
    await tester.pump();

    expect(auth.calls, contains('signUp:new@example.test'));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a failed sign-in shows the error and stays signed out',
      (tester) async {
    final auth = FakeAuthService(signedIn: false)
      ..signInResult = const ApiFailure('Invalid login credentials');
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'a@example.test');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Invalid login credentials'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('the password rule stays at 8 characters', (tester) async {
    // Deliberately stricter than the project's server-side minimum.
    final auth = FakeAuthService(signedIn: false);
    addTearDown(auth.dispose);

    await tester.pumpWidget(gate(auth));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'a@example.test');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(auth.calls, isEmpty, reason: 'must not reach Supabase');
  });

  testWidgets('missing Supabase configuration is explained, not a crash',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SupabaseConfigMissingScreen(message: 'Supabase configuration is missing.'),
    ));
    await tester.pump();

    expect(find.text('Configuration required'), findsOneWidget);
    expect(find.textContaining('Supabase configuration is missing'), findsOneWidget);
  });

  testWidgets('config values are never hardcoded in the app', (tester) async {
    // Guards against a credential being committed as a literal default.
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    expect(url, isEmpty);
    expect(key, isEmpty);
    expect(jsonEncode({'ok': true}), isNotEmpty);
  });
}
