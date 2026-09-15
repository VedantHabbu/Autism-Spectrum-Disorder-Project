import 'dart:convert';

import 'package:asd_nlp_screening_app/core/api_client.dart';
import 'package:asd_nlp_screening_app/core/api_config.dart';
import 'package:asd_nlp_screening_app/features/observation/free_text_observation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('analyzing text displays the returned behavioural events', (tester) async {
    final mockClient = MockClient((request) async {
      expect(request.url.path, '/api/v1/analyze-observation');
      return http.Response(
        jsonEncode({
          'events': [
            {
              'domain': 'response_to_name',
              'status': 'concern',
              'negation_detected': true,
              'evidence': "He doesn't look towards me when I call his name.",
              'confidence': 0.7,
            }
          ],
          'disclaimer': 'This output is an experimental NLP screening-support signal.',
        }),
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FreeTextObservationScreen(apiClient: ApiClient(httpClient: mockClient)),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      "He doesn't look towards me when I call his name.",
    );
    await tester.tap(find.text('Analyze'));
    await tester.pump(); // start the request
    await tester.pump(); // let the mocked future resolve

    expect(find.textContaining('response to name'), findsOneWidget);
    expect(find.text('Concern'), findsOneWidget);
    expect(find.textContaining('Negation detected: yes'), findsOneWidget);
  });

  testWidgets('renders a readable message instead of the raw 422 body', (tester) async {
    // FastAPI returns a list of Pydantic error objects; rendering it
    // directly used to put "[{type: string_too_long, loc: [body, text]...}]"
    // in front of the caregiver.
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'detail': [
            {
              'type': 'string_too_long',
              'loc': ['body', 'text'],
              'msg': 'String should have at most 4000 characters',
              'ctx': {'max_length': 4000},
            }
          ]
        }),
        422,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FreeTextObservationScreen(apiClient: ApiClient(httpClient: mockClient)),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Some observation text.');
    await tester.tap(find.text('Analyze'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('4000-character limit'), findsOneWidget);
    expect(find.textContaining('string_too_long'), findsNothing);
    expect(find.textContaining('loc:'), findsNothing);
  });

  testWidgets('observation field caps input at the backend limit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FreeTextObservationScreen()),
    );

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.maxLength, observationTextMaxLength);
  });

  testWidgets('shows an empty-result message when no domain is recognized', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'events': [], 'disclaimer': 'Not a diagnosis.'}),
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: FreeTextObservationScreen(apiClient: ApiClient(httpClient: mockClient)),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'The weather was nice today.');
    await tester.tap(find.text('Analyze'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No behavioural domain was recognized'), findsOneWidget);
  });
}
