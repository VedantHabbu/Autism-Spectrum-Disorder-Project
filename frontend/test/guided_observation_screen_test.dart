import 'dart:convert';

import 'package:asd_nlp_screening_app/core/api_client.dart';
import 'package:asd_nlp_screening_app/features/observation/guided_observation_screen.dart';
import 'package:asd_nlp_screening_app/models/observation_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The screen is a long scrolling list; off-screen items are never built, so
/// give the test a tall surface rather than scrolling to each prompt.
void useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('sends the selected observation context with a guided answer', (tester) async {
    // Regression: the screen had no context selector, so guided answers were
    // always submitted without the context the plan asks us to capture.
    Map<String, dynamic>? sentBody;
    final mockClient = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'detail': 'pending'}), 503);
    });

    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedObservationScreen(apiClient: ApiClient(httpClient: mockClient)),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<ObservationContext>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playing').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Observed with concern').first);
    await tester.pump();
    await tester.tap(find.text('Submit').first);
    await tester.pump();
    await tester.pump();

    expect(sentBody, isNotNull);
    expect(sentBody!['context'], 'playing');
    expect(sentBody!['choice'], 'observed_with_concern');
    expect(sentBody!['observed_at'], isNotNull);
  });

  testWidgets('a guided answer is still submittable without a context', (tester) async {
    Map<String, dynamic>? sentBody;
    final mockClient = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'detail': 'pending'}), 503);
    });

    useTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedObservationScreen(apiClient: ApiClient(httpClient: mockClient)),
      ),
    );

    await tester.tap(find.text('Not observed').first);
    await tester.pump();
    await tester.tap(find.text('Submit').first);
    await tester.pump();
    await tester.pump();

    expect(sentBody, isNotNull);
    expect(sentBody!.containsKey('context'), isFalse);
    expect(sentBody!['choice'], 'not_observed');
  });
}
