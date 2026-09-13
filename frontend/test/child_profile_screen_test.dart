import 'dart:convert';

import 'package:asd_nlp_screening_app/core/api_client.dart';
import 'package:asd_nlp_screening_app/features/child_profile/child_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('submitting shows the pending-Supabase banner on a 503', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'Persistence is not configured yet: Supabase/PostgreSQL integration is pending'}),
        503,
      );
    });

    await tester.pumpWidget(
      MaterialApp(home: ChildProfileScreen(apiClient: ApiClient(httpClient: mockClient))),
    );

    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.tap(find.text('Create child profile'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('pending'), findsWidgets);
  });

  testWidgets('rejects an empty display name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChildProfileScreen()),
    );

    await tester.tap(find.text('Create child profile'));
    await tester.pump();

    expect(find.text('Enter a display name'), findsOneWidget);
  });
}
