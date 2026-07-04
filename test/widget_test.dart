import 'package:flutter_test/flutter_test.dart';

import 'package:project_fuel/main.dart';

void main() {
  testWidgets('shows a splash screen before navigating to login', (
    tester,
  ) async {
    await tester.pumpWidget(const ProjectFuelApp());

    expect(find.text('FleetSense'), findsOneWidget);
    expect(find.text('Fuel delivery coordination made simple'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Smart Fuel Delivery Management'), findsOneWidget);
  });
}
