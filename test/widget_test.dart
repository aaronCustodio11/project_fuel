import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_fuel/features/supervisor/pages/user_dashboard_page.dart';

void main() {
  testWidgets('shows the user dashboard content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UserDashboard()));
    await tester.pump();

    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Add User'), findsOneWidget);
  });
}
