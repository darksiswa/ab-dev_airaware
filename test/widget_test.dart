import 'package:air_aware/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows AirAware splash text', (tester) async {
    await tester.pumpWidget(const AirAwareApp());

    expect(find.text('AirAware'), findsOneWidget);
    expect(find.text('Breathe Smarter'), findsOneWidget);
  });
}
