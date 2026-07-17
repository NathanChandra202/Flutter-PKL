import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kostraktor/providers/auth_provider.dart';
import 'package:kostraktor/screens/splash_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
