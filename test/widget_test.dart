import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arch_dev/widgets/status_badge.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('renders label and colour', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(label: 'Enquiry', color: Colors.orange),
          ),
        ),
      );

      expect(find.text('Enquiry'), findsOneWidget);
    });

    testWidgets('renders with different status labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(label: 'Submitted', color: Colors.blue),
          ),
        ),
      );

      expect(find.text('Submitted'), findsOneWidget);
    });
  });
}
