import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:small_business_manager/main.dart';
import 'package:small_business_manager/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('AuthGate renders without crashing during session check', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: AuthGate()),
      ),
    );

    // Should render something (loading or auth screen) without throwing
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Should find the outer MaterialApp provided in the test
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
