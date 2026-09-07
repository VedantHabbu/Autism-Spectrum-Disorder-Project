import 'package:asd_nlp_screening_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Week 1 foundation screen', (tester) async {
    await tester.pumpWidget(const ScreeningSupportApp());

    expect(find.text('Week 1 foundation'), findsOneWidget);
    expect(find.textContaining('does not diagnose'), findsOneWidget);
  });
}
