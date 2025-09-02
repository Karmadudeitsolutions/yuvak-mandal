import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandal_loan_system/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app launches without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Check if login elements are present
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Sign in to continue to Yuvak Mandal'), findsOneWidget);
  });
}