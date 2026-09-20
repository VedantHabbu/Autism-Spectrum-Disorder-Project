import 'dart:convert';

import 'package:asd_nlp_screening_app/core/api_client.dart';
import 'package:asd_nlp_screening_app/features/home/home_screen.dart';
import 'package:asd_nlp_screening_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_auth_service.dart';

void main() {
  testWidgets('renders the app home screen with the safety disclaimer', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({'status': 'ok'}), 200);
    });

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(apiClient: ApiClient(httpClient: mockClient))),
    );
    await tester.pump();

    expect(find.text('ASD Screening Support'), findsWidgets);
    expect(find.textContaining('does not diagnose ASD'), findsOneWidget);
  });

  testWidgets('shows backend-unreachable status when the health check fails', (tester) async {
    final mockClient = MockClient((request) async => http.Response('', 500));

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(apiClient: ApiClient(httpClient: mockClient))),
    );
    await tester.pump();

    expect(find.text('Backend unreachable'), findsOneWidget);
  });

  testWidgets('app entry point builds ScreeningSupportApp', (tester) async {
    final mockClient = MockClient((request) async => http.Response('', 500));

    final auth = FakeAuthService(signedIn: true, email: 'caregiver@example.test');
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ScreeningSupportApp(
        apiClient: ApiClient(httpClient: mockClient),
        authService: auth,
      ),
    );
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
