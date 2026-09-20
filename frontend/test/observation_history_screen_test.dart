import 'dart:convert';

import 'package:asd_nlp_screening_app/core/api_client.dart';
import 'package:asd_nlp_screening_app/features/observation/observation_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Widget screenWith(MockClient client) => MaterialApp(
        home: ObservationHistoryScreen(apiClient: ApiClient(httpClient: client)),
      );

  testWidgets('renders structured observation fields, not a raw map dump', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'child_id': '22222222-2222-4222-8222-222222222222',
            'observation_period_id': '33333333-3333-4333-8333-333333333333',
            'source_type': 'free_text',
            'text': 'He waved goodbye at the door.',
            'context': 'outdoors',
            'observed_at': '2026-09-05T10:30:00Z',
            'created_at': '2026-09-05T10:31:00Z',
          }
        ]),
        200,
      );
    });

    await tester.pumpWidget(screenWith(mockClient));
    await tester.tap(find.text('Load history'));
    await tester.pump();
    await tester.pump();

    expect(find.text('He waved goodbye at the door.'), findsOneWidget);
    expect(find.text('Free text'), findsOneWidget);
    expect(find.text('Outdoors'), findsOneWidget);
    // The raw-map rendering that this replaced would have shown these.
    expect(find.textContaining('source_type:'), findsNothing);
    expect(find.textContaining('{'), findsNothing);
  });

  testWidgets('a guided entry without a note is labelled rather than blank', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'child_id': '22222222-2222-4222-8222-222222222222',
            'observation_period_id': null,
            'source_type': 'guided',
            'text': null,
            'context': null,
            'observed_at': '2026-09-05T10:30:00Z',
            'created_at': '2026-09-05T10:31:00Z',
          }
        ]),
        200,
      );
    });

    await tester.pumpWidget(screenWith(mockClient));
    await tester.tap(find.text('Load history'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Guided'), findsOneWidget);
    expect(find.textContaining('No free-text note'), findsOneWidget);
  });

  testWidgets('shows the pending banner while persistence is unavailable', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({'detail': 'Persistence is not configured yet'}), 503);
    });

    await tester.pumpWidget(screenWith(mockClient));
    await tester.tap(find.text('Load history'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('not configured yet'), findsOneWidget);
  });
}
