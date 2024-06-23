import 'package:dayplanner/common_widgets/showDialog.dart';
import 'package:dayplanner/main.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFunction extends Mock {
  Future<void> call(String controllerText, Function(String?) setError);
}

void main() {
  testWidgets('Go to LogIn Page', (WidgetTester tester) async {

    await tester.pumpWidget(const MyApp());

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey("loginButton")));
    await tester.pumpAndSettle();

    expect(find.text("Log In into your account"), findsOneWidget);
    expect(find.text("Log In"), findsOneWidget);
    expect(find.text("Sign Up"), findsNothing);
  });

  testWidgets('Go to SignUp Page', (WidgetTester tester) async {

    await tester.pumpWidget(const MyApp());

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey("signupButton")));
    await tester.pumpAndSettle();

    expect(find.text("Sign Up"), findsOneWidget);
    expect(find.text("Log In"), findsNothing);
  });

  testWidgets('Test showDialog widget', (WidgetTester tester) async {
    final mockFunction = MockFunction();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ShowDialog(
                    title: 'Test Dialog',
                    inputText: 'Enter something',
                    buttonText: 'Submit',
                    onPressedFunction: mockFunction.call,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Test Dialog'), findsOneWidget);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Enter something'), findsOneWidget);

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('Test Cancel button in showDialog widget', (WidgetTester tester) async {
    final mockFunction = MockFunction();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ShowDialog(
                    title: 'Test Dialog',
                    inputText: 'Enter something',
                    buttonText: 'Submit',
                    onPressedFunction: mockFunction.call,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Test Dialog'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Test Dialog'), findsNothing);
  });

  testWidgets('Test validation in ShowDialog widget - open dialog and enter text', (WidgetTester tester) async {
    final mockFunction = MockFunction();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ShowDialog(
                    title: 'Test Dialog',
                    inputText: 'Enter something',
                    buttonText: 'Submit',
                    onPressedFunction: mockFunction.call,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(ShowDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Some text');
    await tester.pump();
  });
}